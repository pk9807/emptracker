from mcp.server.fastmcp import FastMCP

mcp = FastMCP("My First MCP Server")


@mcp.tool()
def greet(name: str) -> str:
    """Greet a person by name."""
    return f"Hello {name}! 👋 Tumhara pehla MCP tool successfully chal raha hai."


if __name__ == "__main__":
    mcp.run()
