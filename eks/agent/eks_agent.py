"""
Nova EKS Agent — AI-powered EKS cluster management.
Uses Amazon Nova Pro on Bedrock (no Anthropic API key needed).
"""
import json
import boto3
import typer
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

app = typer.Typer(help="Nova EKS Agent — AI-managed Kubernetes operations")
console = Console()

BEDROCK_REGION = "us-east-1"
MODEL_ID = "amazon.nova-pro-v1:0"
AWS_REGION = "eu-west-1"
CLUSTER_NAME = "nova-eks"

SYSTEM_PROMPT = """You are Nova, an AI agent that manages an EKS Kubernetes cluster.
You have tools to inspect cluster health, list nodes and pods, check for issues,
and scale node groups. Always start by checking cluster status before acting.
Be conservative: only scale or restart things when clearly needed.
Explain your reasoning before each action."""

TOOLS = [
    {
        "toolSpec": {
            "name": "describe_cluster",
            "description": "Get EKS cluster status, version, and endpoint.",
            "inputSchema": {"json": {
                "type": "object",
                "properties": {
                    "cluster_name": {"type": "string", "description": "EKS cluster name"},
                    "region": {"type": "string", "description": "AWS region"},
                },
                "required": ["cluster_name", "region"],
            }},
        }
    },
    {
        "toolSpec": {
            "name": "list_nodes",
            "description": "List all nodes in the cluster with status, instance type, and resource usage.",
            "inputSchema": {"json": {
                "type": "object",
                "properties": {
                    "cluster_name": {"type": "string"},
                    "region": {"type": "string"},
                },
                "required": ["cluster_name", "region"],
            }},
        }
    },
    {
        "toolSpec": {
            "name": "list_node_groups",
            "description": "List EKS managed node groups with current/desired/min/max sizes.",
            "inputSchema": {"json": {
                "type": "object",
                "properties": {
                    "cluster_name": {"type": "string"},
                    "region": {"type": "string"},
                },
                "required": ["cluster_name", "region"],
            }},
        }
    },
    {
        "toolSpec": {
            "name": "scale_node_group",
            "description": "Scale an EKS managed node group to a new desired size.",
            "inputSchema": {"json": {
                "type": "object",
                "properties": {
                    "cluster_name": {"type": "string"},
                    "region": {"type": "string"},
                    "node_group_name": {"type": "string", "description": "Node group name"},
                    "desired_size": {"type": "integer", "description": "New desired number of nodes (1-10)"},
                    "reason": {"type": "string", "description": "Why you are scaling"},
                },
                "required": ["cluster_name", "region", "node_group_name", "desired_size", "reason"],
            }},
        }
    },
    {
        "toolSpec": {
            "name": "get_node_group_health",
            "description": "Check the health of a node group and list any issues.",
            "inputSchema": {"json": {
                "type": "object",
                "properties": {
                    "cluster_name": {"type": "string"},
                    "region": {"type": "string"},
                    "node_group_name": {"type": "string"},
                },
                "required": ["cluster_name", "region", "node_group_name"],
            }},
        }
    },
    {
        "toolSpec": {
            "name": "get_cloudwatch_metrics",
            "description": "Get CPU and memory utilization metrics for the cluster nodes over the last hour.",
            "inputSchema": {"json": {
                "type": "object",
                "properties": {
                    "cluster_name": {"type": "string"},
                    "region": {"type": "string"},
                },
                "required": ["cluster_name", "region"],
            }},
        }
    },
]


def execute_tool(name: str, inputs: dict) -> dict:
    region = inputs.get("region", AWS_REGION)
    cluster = inputs.get("cluster_name", CLUSTER_NAME)

    try:
        if name == "describe_cluster":
            eks = boto3.client("eks", region_name=region)
            r = eks.describe_cluster(name=cluster)
            c = r["cluster"]
            return {
                "name": c["name"],
                "status": c["status"],
                "version": c["version"],
                "endpoint": c.get("endpoint", ""),
                "role_arn": c.get("roleArn", ""),
                "logging": c.get("logging", {}),
            }

        if name == "list_nodes":
            eks = boto3.client("eks", region_name=region)
            # Get nodes via EC2 (nodes are EC2 instances tagged with the cluster)
            ec2 = boto3.client("ec2", region_name=region)
            instances = ec2.describe_instances(Filters=[
                {"Name": "tag:aws:eks:cluster-name", "Values": [cluster]},
                {"Name": "instance-state-name", "Values": ["running", "pending"]},
            ])
            nodes = []
            for r in instances["Reservations"]:
                for i in r["Instances"]:
                    name_tag = next((t["Value"] for t in i.get("Tags", []) if t["Key"] == "Name"), "")
                    nodes.append({
                        "instance_id": i["InstanceId"],
                        "name": name_tag,
                        "type": i["InstanceType"],
                        "state": i["State"]["Name"],
                        "az": i["Placement"]["AvailabilityZone"],
                        "private_ip": i.get("PrivateIpAddress", ""),
                        "launch_time": str(i.get("LaunchTime", "")),
                    })
            return {"node_count": len(nodes), "nodes": nodes}

        if name == "list_node_groups":
            eks = boto3.client("eks", region_name=region)
            ngs = eks.list_node_groups(clusterName=cluster)["nodegroups"]
            result = []
            for ng_name in ngs:
                ng = eks.describe_node_group(clusterName=cluster, nodegroupName=ng_name)["nodegroup"]
                result.append({
                    "name": ng["nodegroupName"],
                    "status": ng["status"],
                    "instance_types": ng.get("instanceTypes", []),
                    "desired": ng["scalingConfig"]["desiredSize"],
                    "min": ng["scalingConfig"]["minSize"],
                    "max": ng["scalingConfig"]["maxSize"],
                    "ami_type": ng.get("amiType", ""),
                    "capacity_type": ng.get("capacityType", "ON_DEMAND"),
                })
            return {"node_groups": result}

        if name == "scale_node_group":
            ng_name = inputs["node_group_name"]
            desired = inputs["desired_size"]
            if desired < 1 or desired > 10:
                return {"error": f"desired_size must be between 1 and 10, got {desired}"}
            eks = boto3.client("eks", region_name=region)
            eks.update_node_group_config(
                clusterName=cluster,
                nodegroupName=ng_name,
                scalingConfig={"desiredSize": desired},
            )
            return {"status": "scaling_initiated", "node_group": ng_name, "desired_size": desired, "reason": inputs["reason"]}

        if name == "get_node_group_health":
            ng_name = inputs["node_group_name"]
            eks = boto3.client("eks", region_name=region)
            ng = eks.describe_node_group(clusterName=cluster, nodegroupName=ng_name)["nodegroup"]
            health = ng.get("health", {})
            return {
                "node_group": ng_name,
                "status": ng["status"],
                "health_issues": health.get("issues", []),
                "current_desired": ng["scalingConfig"]["desiredSize"],
                "current_count": ng.get("resources", {}).get("autoScalingGroups", []),
            }

        if name == "get_cloudwatch_metrics":
            from datetime import datetime, timezone, timedelta
            cw = boto3.client("cloudwatch", region_name=region)
            end = datetime.now(timezone.utc)
            start = end - timedelta(hours=1)

            cpu = cw.get_metric_statistics(
                Namespace="AWS/EKS",
                MetricName="node_cpu_utilization",
                Dimensions=[{"Name": "ClusterName", "Value": cluster}],
                StartTime=start, EndTime=end,
                Period=3600, Statistics=["Average"],
            )
            return {
                "cpu_avg_1h": round(cpu["Datapoints"][0]["Average"], 2) if cpu["Datapoints"] else "no_data",
                "period": "last 1 hour",
            }

        return {"error": f"Unknown tool: {name}"}

    except Exception as e:
        return {"error": str(e)}


def run_agent(task: str, dry_run: bool = True):
    client = boto3.client("bedrock-runtime", region_name=BEDROCK_REGION)

    mode = "DRY RUN" if dry_run else "LIVE"
    console.print(Panel(
        f"[bold]Task:[/bold] {task}\n[bold]Cluster:[/bold] {CLUSTER_NAME} | [bold]Mode:[/bold] {mode}",
        title="Nova EKS Agent",
        border_style="blue",
    ))

    messages = [{"role": "user", "content": [{"text": task}]}]

    while True:
        try:
            response = client.converse(
                modelId=MODEL_ID,
                system=[{"text": SYSTEM_PROMPT}],
                messages=messages,
                toolConfig={"tools": TOOLS},
                inferenceConfig={"maxTokens": 4096},
            )
        except Exception as e:
            console.print(f"[red]Agent error: {e}[/red]")
            break

        output = response["output"]["message"]
        stop_reason = response["stopReason"]

        for block in output["content"]:
            if "text" in block and block["text"].strip():
                console.print(f"\n{block['text']}")

        if stop_reason != "tool_use":
            break

        tool_uses = [b for b in output["content"] if "toolUse" in b]
        messages.append(output)

        tool_results = []
        for block in tool_uses:
            call = block["toolUse"]
            tool_name = call["name"]
            tool_input = call["input"]

            console.print(f"\n  [cyan]→ {tool_name}[/cyan]", end=" ")

            # Guard: don't actually scale in dry-run mode
            if dry_run and tool_name == "scale_node_group":
                result = {
                    "status": "dry_run",
                    "message": f"DRY RUN — would scale {tool_input.get('node_group_name')} to {tool_input.get('desired_size')} nodes",
                }
                console.print("[yellow][DRY RUN][/yellow]")
            else:
                result = execute_tool(tool_name, tool_input)
                console.print("[green]done[/green]")

            tool_results.append({
                "toolResult": {
                    "toolUseId": call["toolUseId"],
                    "content": [{"text": json.dumps(result, default=str)}],
                }
            })

        messages.append({"role": "user", "content": tool_results})


# ─── CLI ───────────────────────────────────────────────────────────────────────

@app.command()
def status(
    cluster: str = typer.Option(CLUSTER_NAME, help="EKS cluster name"),
    region: str = typer.Option(AWS_REGION, help="AWS region"),
):
    """Check cluster health and node status."""
    global CLUSTER_NAME, AWS_REGION
    CLUSTER_NAME = cluster
    AWS_REGION = region
    run_agent(
        f"Check the health of EKS cluster '{cluster}'. "
        "Describe the cluster, list all node groups and their status, "
        "check for any health issues, and summarize the current state.",
        dry_run=True,
    )


@app.command()
def scale(
    node_group: str = typer.Argument(..., help="Node group name to scale"),
    desired: int = typer.Argument(..., help="Desired number of nodes"),
    cluster: str = typer.Option(CLUSTER_NAME, help="EKS cluster name"),
    region: str = typer.Option(AWS_REGION, help="AWS region"),
    dry_run: bool = typer.Option(True, help="Dry run (no real changes)"),
):
    """Scale a node group. Agent will verify before acting."""
    global CLUSTER_NAME, AWS_REGION
    CLUSTER_NAME = cluster
    AWS_REGION = region
    run_agent(
        f"Scale node group '{node_group}' in cluster '{cluster}' to {desired} nodes. "
        "First check the current state of the cluster and node group. "
        "Then scale if it makes sense and explain why.",
        dry_run=dry_run,
    )


@app.command()
def investigate(
    task: str = typer.Argument(..., help="What to investigate (e.g. 'why are nodes unhealthy')"),
    cluster: str = typer.Option(CLUSTER_NAME, help="EKS cluster name"),
    region: str = typer.Option(AWS_REGION, help="AWS region"),
):
    """Ask the agent to investigate any EKS issue."""
    global CLUSTER_NAME, AWS_REGION
    CLUSTER_NAME = cluster
    AWS_REGION = region
    run_agent(task, dry_run=True)


if __name__ == "__main__":
    app()
