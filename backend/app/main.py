import logging

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)

logger = logging.getLogger("cloud-provisioner")


app = FastAPI(
    title="Cloud Provisioner API",
    description="Backend API for the Cloud Infrastructure Provisioning Platform",
    version="0.2.0",
)


class Resource(BaseModel):
    name: str
    resource_type: str
    environment: str


resources = []


@app.get("/")
def root():
    logger.info("Root endpoint accessed")

    return {
        "message": "Cloud Provisioner API is running"
    }


@app.get("/health")
def health_check():
    logger.info("Health check requested")

    return {
        "status": "healthy",
        "service": "cloud-provisioner-api",
    }


@app.post("/resources", status_code=201)
def create_resource(resource: Resource):
    logger.info(
        "Creating resource: name=%s type=%s environment=%s",
        resource.name,
        resource.resource_type,
        resource.environment,
    )

    resources.append(resource)

    logger.info(
        "Resource created successfully: name=%s",
        resource.name,
    )

    return {
        "message": "Resource created successfully",
        "resource": resource,
    }


@app.get("/resources")
def get_resources():
    logger.info("Fetching all resources")

    return {
        "resources": resources
    }


@app.get("/resources/{resource_name}")
def get_resource(resource_name: str):
    logger.info(
        "Fetching resource: name=%s",
        resource_name,
    )

    for resource in resources:
        if resource.name == resource_name:
            logger.info(
                "Resource found: name=%s",
                resource_name,
            )

            return resource

    logger.warning(
        "Resource not found: name=%s",
        resource_name,
    )

    raise HTTPException(
        status_code=404,
        detail="Resource not found",
    )