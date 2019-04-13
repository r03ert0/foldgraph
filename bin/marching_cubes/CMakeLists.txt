cmake_minimum_required(VERSION 3.1)
project(marching_cubes)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
find_package(LIBIGL REQUIRED QUIET)

# project files
file(GLOB SRCFILES *.cpp)
add_executable(${PROJECT_NAME} ${SRCFILES})
target_link_libraries(${PROJECT_NAME} igl::core)
