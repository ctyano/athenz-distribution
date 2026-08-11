import os
import json
import logging
from fastmcp import FastMCP
from fastmcp.server.auth import JWTVerifier
from starlette.applications import Starlette
from starlette.middleware import Middleware
from starlette.requests import Request
from starlette.responses import JSONResponse

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("athenz-mcp-server")

ZTS_BASE_URL = os.environ.get("ZTS_BASE_URL", "https://athenz-zts-server.athenz:4443/zts/v1")
JWKS_URI = os.environ.get("JWKS_URI", f"{ZTS_BASE_URL}/oauth2/keys?rfc=true")
ISSUER = os.environ.get("ISSUER", ZTS_BASE_URL)
AUDIENCE = os.environ.get("AUDIENCE", "mcp")
REQUIRED_WRITE_SCOPE = os.environ.get("REQUIRED_WRITE_SCOPE", "mcp:action.write")

jwt_verifier = JWTVerifier(
    jwks_uri=JWKS_URI,
    issuer=ISSUER,
    audience=AUDIENCE,
)

mcp = FastMCP(
    "athenz-mcp-server",
    auth=jwt_verifier,
)


@mcp.tool()
def get_server_info() -> str:
    return json.dumps({
        "name": "athenz-mcp-server",
        "version": "1.0.0",
        "description": "Athenz MCP Server with JWT-based authorization",
    })


@mcp.tool()
def read_data(key: str) -> str:
    data = {
        "server": "athenz-mcp",
        "status": "running",
    }
    value = data.get(key, f"key '{key}' not found")
    return json.dumps({"key": key, "value": value})


@mcp.tool()
def write_data(key: str, value: str) -> str:
    logger.info("write_data called: key=%s value=%s", key, value)
    return json.dumps({
        "status": "success",
        "key": key,
        "value": value,
    })


async def scope_authorization_middleware(app, scope, receive, send):
    if scope["type"] != "http":
        return await app(scope, receive, send)

    request = Request(scope, receive)

    if request.url.path != "/mcp":
        return await app(scope, receive, send)

    body_bytes = b""
    async for chunk in receive():
        body_bytes += chunk

    try:
        body = json.loads(body_bytes)
    except (json.JSONDecodeError, UnicodeDecodeError):
        body = {}

    method = body.get("method", "")
    tool_name = body.get("params", {}).get("name", "") if method == "tools/call" else ""

    auth_header = request.headers.get("authorization", "")
    token = auth_header[7:] if auth_header.startswith("Bearer ") else ""

    if token:
        try:
            claims = await jwt_verifier.verify_token(token)
            logger.info(
                "MCP request: method=%s tool=%s sub=%s client_id=%s aud=%s scope=%s",
                method,
                tool_name or "-",
                claims.get("sub", ""),
                claims.get("client_id", ""),
                claims.get("aud", ""),
                claims.get("scope", ""),
            )
        except Exception as e:
            logger.warning("Token verification failed: method=%s error=%s", method, e)
            if method == "tools/call":
                response = JSONResponse(
                    {"jsonrpc": "2.0", "error": {"code": -32001, "message": "Invalid token"}, "id": body.get("id")},
                    status_code=401,
                )
                await response(scope, receive, send)
                return
    elif method == "tools/call":
        response = JSONResponse(
            {"jsonrpc": "2.0", "error": {"code": -32001, "message": "Missing Bearer token"}, "id": body.get("id")},
            status_code=401,
        )
        await response(scope, receive, send)
        return

    if method == "tools/call":
        scopes_str = claims.get("scope", "")
        if isinstance(scopes_str, list):
            scopes = scopes_str
        else:
            scopes = scopes_str.split() if scopes_str else []

        if REQUIRED_WRITE_SCOPE not in scopes:
            logger.warning("write access denied: required=%s scopes=%s", REQUIRED_WRITE_SCOPE, scopes)
            response = JSONResponse(
                {"jsonrpc": "2.0", "error": {"code": -32001, "message": f"Insufficient scope: {REQUIRED_WRITE_SCOPE} required for write"}, "id": body.get("id")},
                status_code=403,
            )
            await response(scope, receive, send)
            return

    async def receive():
        return {"type": "http.request", "body": body_bytes}

    return await app(scope, receive, send)


app = Starlette(
    middleware=[Middleware(scope_authorization_middleware)],
    routes=[],
)
app.mount("/", mcp.sse_app())
