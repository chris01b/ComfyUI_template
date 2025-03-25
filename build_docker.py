#!/usr/bin/env python3
import datetime
import os
import subprocess
import logging
import argparse

"""
Build Docker script for ComfyUI Docker images.

Example usage:
- Basic build: ./build_docker.py comfyui-without-flux
- With HuggingFace token: ./build_docker.py comfyui-without-flux --hf-token your_token_here
  (Using --hf-token will enable authenticated downloads from HuggingFace during build)
- Tag as latest: ./build_docker.py comfyui-without-flux --latest
- Specify username: ./build_docker.py comfyui-without-flux --username your_docker_username
"""

today_tag = datetime.datetime.now().strftime("%d%m%Y")

# Creating argparse parser
parser = argparse.ArgumentParser(description="Build Dockerfile")
parser.add_argument('docker', type=str, help='Name of the Dockerfile to build - should match a folder name in this repo')
parser.add_argument('--username', type=str, default="chris01b", help=f"Tag to use. Defaults to today's date: chris01b")
parser.add_argument('--tag', type=str, default=today_tag, help=f"Tag to use. Defaults to today's date: {today_tag}")
parser.add_argument('--latest', action="store_true", help='If specified, we will also tag and push :latest')
parser.add_argument('--hf-token', type=str, help='HuggingFace token to use for model downloads during build')
args = parser.parse_args()

logger = logging.getLogger()
logging.basicConfig(
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s", level=logging.INFO, datefmt="%Y-%m-%d %H:%M:%S"
)

dockerLLM_dir = os.path.dirname(os.path.realpath(__file__))
username = args.username

def docker_command(command):
    try:
        # Mask the HF token in logs if present
        log_command = command
        if "HF_TOKEN=" in log_command:
            log_command = log_command.split("HF_TOKEN=")[0] + "HF_TOKEN=***" + log_command.split("HF_TOKEN=")[1].split(" ")[1]
        
        logger.info(f"Running docker command: {log_command}")
        subprocess.check_call(command, shell=True)
    except subprocess.CalledProcessError as e:
        logger.error(f"Got error while executing docker command: {e}")
        raise
    except Exception as e:
        raise e

def build(docker_repo, tag, from_docker=None, hf_token=None):
    docker_container = f"{username}/{docker_repo}:{tag}"
    logger.info(f"Building and pushing {docker_container}")

    docker_build_arg = f"--progress=plain -t {docker_container}"
    if from_docker is not None:
        docker_build_arg += f" --build-arg DOCKER_FROM={from_docker}"
    
    if hf_token is not None:
        docker_build_arg += f" --build-arg HF_TOKEN={hf_token}"
        logger.info("Using provided HuggingFace token for build")

    build_command = f"docker build {docker_build_arg} {dockerLLM_dir}/{docker_repo}"
    push_command = f"docker push {docker_container}"

    docker_command(build_command)
    docker_command(push_command)

    return docker_container

def tag(source_container, target_container):
    tag_command = f"docker tag {source_container} {target_container}"
    docker_command(tag_command)
    docker_command(f"docker push {target_container}")


try:
    container = build(args.docker, args.tag, hf_token=args.hf_token)
    logger.info(f"Successfully built and pushed the container to {container}")

    if args.latest:
        latest = f"{username}/{args.docker}:latest"
        tag(container, latest)
        logger.info(f"Successfully tagged and pushed to {latest}")

except subprocess.CalledProcessError as e:
    logger.error(f"Process aborted due to error running Docker commands")
except Exception as e:
    raise e

