# syntax=docker/dockerfile-upstream:master-labs

FROM osrf/ros:humble-desktop-full
LABEL maintainer="Bhargav Chandaka <bhargav9@illinois.edu>"
ENV USER_NAME="user"
ENV TERM="xterm-256color"

# Use local mirrors for faster deployment
RUN sed -i -e 's/http:\/\/archive\.ubuntu\.com\/ubuntu\//mirror:\/\/mirrors\.ubuntu\.com\/mirrors\.txt/' /etc/apt/sources.list

RUN sudo apt-get update
# Create ubuntu user with sudo privileges
RUN useradd -ms /bin/bash $USER_NAME && \
    usermod -aG sudo $USER_NAME && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    sed -i 's/required/sufficient/' /etc/pam.d/chsh && \
    touch /home/$USER_NAME/.sudo_as_admin_successful

USER $USER_NAME

# Install tmux & tmuxinator
RUN sudo apt install -y tmux
RUN mkdir $HOME/tmp && export TMPDIR=$HOME/tmp
RUN sudo gem install tmuxinator
WORKDIR /home/$USER_NAME
RUN git clone https://github.com/gpakosz/.tmux.git
RUN ln -s -f .tmux/.tmux.conf
COPY ./docker_settings/.tmux.conf.local /home/$USER_NAME/
RUN sudo chown $USER_NAME /home/$USER_NAME/.tmux.conf.local

# Update dependencies with rosdep
RUN sudo apt-get update
# RUN sudo apt-get install  
WORKDIR /home/$USER_NAME/colcon_ws
RUN sudo apt-get install -y python3-rosdep
RUN rosdep update
COPY --parents src/**/*.xml /tmp
COPY --parents src/**/COLCON_IGNORE /tmp
RUN cd /tmp && rosdep install -i --from-path . --rosdistro humble -y

# Install ROS2/Additional dependencies
RUN sudo apt-get install -y htop
RUN sudo apt-get install -y ros-humble-gazebo-*
RUN sudo apt-get install -y ros-humble-dynamixel-sdk ros-humble-ros2-control ros-humble-ros2-controllers ros-humble-gripper-controllers ros-humble-moveit ros-humble-moveit-servo
RUN sudo apt-get install -y ros-humble-turtlebot3
RUN sudo apt-get update
RUN sudo apt-get upgrade -y 

# bash settings
COPY ./docker_settings/.bashrc /tmp/.bashrc
RUN cat /tmp/.bashrc >> /home/$USER_NAME/.bashrc

# Install Python dependencies
RUN sudo apt-get install -y python3-pip
COPY ./requirements.txt /tmp
RUN pip3 install -r /tmp/requirements.txt

RUN export PATH="$HOME/.local/bin:$PATH"
WORKDIR /home/$USER_NAME/colcon_ws
USER root

CMD ["/usr/bin/bash"]
