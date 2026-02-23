ARG IMAGE=ubuntu
ARG RELEASE=24.04

# Use the specified base image
FROM rightclickscript/devcontainers:${IMAGE}-${RELEASE}

# Echo the values of the ARG variables
RUN echo "IMAGE=${IMAGE}" && echo "RELEASE=${RELEASE}" && echo "USER_NAME=${USER_NAME}"

# Install system packages as root
USER root

RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3-pip \
    python3-venv \
    openssh-server \
    openssh-client \
    software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Helm
# RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null \
#     && apt-get install apt-transport-https --yes \
#     && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
#     && apt-get update \
#     && apt-get install -y helm

RUN curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && sudo apt-get update \
    && sudo apt-get install -y helm

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Install build tools needed for nvm and other packages
RUN apt-get update && apt-get install -y curl build-essential

ARG USER_NAME
# Switch to the non-root user FIRST
USER ${USER_NAME}

# <<< START: FINAL CORRECTED SECTION >>>
# Set environment variables for the non-root user
ENV NVM_DIR="/home/${USER_NAME}/.nvm"
ENV NODE_VERSION=20

# Install nvm, Node.js, and Gemini CLI as the non-root user
RUN bash -c " \
    # Install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash; \
    # Source nvm script for this RUN command's context
    . ${NVM_DIR}/nvm.sh; \
    # Install, use, and set default Node.js version
    nvm install ${NODE_VERSION} && nvm use ${NODE_VERSION} && nvm alias default ${NODE_VERSION}; \
    # Install the Gemini CLI
    npm install -g @google/gemini-cli"

# ** This is the crucial part that was missing **
# Add nvm sourcing to the shell startup files for interactive sessions
RUN echo '\nexport NVM_DIR="/home/${USER_NAME}/.nvm"' >> /home/${USER_NAME}/.zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> /home/${USER_NAME}/.zshrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> /home/${USER_NAME}/.zshrc && \
    echo '\nexport NVM_DIR="/home/${USER_NAME}/.nvm"' >> /home/${USER_NAME}/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/${USER_NAME}/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/${USER_NAME}/.bashrc
# <<< END: FINAL CORRECTED SECTION >>>

# Create a virtual environment
RUN python3 -m venv /home/${USER_NAME}/.venv

# Activate the virtual environment for subsequent commands
ENV USERNAME=${USER_NAME}
ENV PATH="/home/${USERNAME}/.venv/bin:${PATH}"

# Set environment variables
ENV ANSIBLE_HOME=/home/${USERNAME}/.ansible
ENV ANSIBLE_CONFIG=${ANSIBLE_HOME}/ansible.cfg

# Install Ansible and other packages in the virtual environment
RUN pip3 install ansible-core \
    ansible-lint \
    kubernetes \
    pylxd \
    jmespath

RUN /home/${USERNAME}/.venv/bin/ansible-galaxy collection install ansible.utils \
    && /home/${USERNAME}/.venv/bin/ansible-galaxy collection install community.general \
    && /home/${USERNAME}/.venv/bin/pip install netaddr \
    && /home/${USERNAME}/.venv/bin/ansible-galaxy collection install ansible.posix \
    && /home/${USERNAME}/.venv/bin/ansible-galaxy collection install kubernetes.core \
    && /home/${USERNAME}/.venv/bin/ansible-galaxy collection install community.docker

# Set working directory
WORKDIR /home/${USERNAME}/
