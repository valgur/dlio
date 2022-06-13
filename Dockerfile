ARG ROS_DISTRO=noetic
FROM ros:$ROS_DISTRO

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get dist-upgrade -y && \
    apt-get install software-properties-common python3-pip ninja-build git -y && \
    add-apt-repository ppa:borglab/gtsam-develop -y -u && \
    apt-get install libgtsam-dev libgtsam-unstable-dev libtbb-dev -y && \
    python3 -m pip install -U catkin_tools

RUN mkdir -p /catkin_ws/src && cd catkin_ws && catkin init
WORKDIR /catkin_ws/src

RUN git clone https://github.com/opencv/opencv.git --depth=1 && \
    git clone https://github.com/opencv/opencv_contrib.git --depth=1 && \
    cd opencv && mkdir build && cd build && \
    cmake .. -G Ninja -DCMAKE_INSTALL_PREFIX=/catkin_ws/src/opencv/install \
      -DOPENCV_EXTRA_MODULES_PATH=/catkin_ws/src/opencv_contrib/modules \
      -DOPENCV_ENABLE_NONFREE=ON -DBUILD_LIST=core,highgui,features2d,xfeatures2d && \
    ninja install

COPY cartographer/package.xml cartographer/
COPY cartographer_ros/cartographer_ros/package.xml cartographer_ros/cartographer_ros/
COPY cartographer_ros/cartographer_ros_msgs/package.xml cartographer_ros/cartographer_ros_msgs/
COPY cartographer_ros/cartographer_rviz/package.xml cartographer_ros/cartographer_rviz/
COPY dlio/package.xml dlio/
RUN rosdep install --from-paths . --ignore-src --rosdistro=$ROS_DISTRO -y -r

COPY . .
# https://github.com/ethz-asl/lidar_align/issues/16#issuecomment-504348488
RUN if [ "$ROS_DISTRO" = "melodic" ]; then \
      rm /usr/include/flann/ext/lz4.h /usr/include/flann/ext/lz4hc.h && \
      ln -s /usr/include/lz4.h /usr/include/flann/ext/lz4.h && \
      ln -s /usr/include/lz4hc.h /usr/include/flann/ext/lz4hc.h; \
    fi;
RUN . /opt/ros/$ROS_DISTRO/setup.sh && \
    catkin build --no-status --summary --force-color \
      -DOpenCV_DIR=/catkin_ws/src/opencv/install/lib/cmake/opencv4
