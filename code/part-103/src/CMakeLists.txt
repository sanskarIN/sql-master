cmake_minimum_required(VERSION 3.20)
project(sql_full_mastery_part_103 LANGUAGES C CXX)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(SQLite3 REQUIRED)

add_executable(sqlite_c_example sqlite_c_example.c)
target_link_libraries(sqlite_c_example PRIVATE SQLite::SQLite3)

add_executable(sqlite_cpp_raii sqlite_cpp_raii.cpp)
target_link_libraries(sqlite_cpp_raii PRIVATE SQLite::SQLite3)

if(MSVC)
  target_compile_options(sqlite_c_example PRIVATE /W4 /permissive-)
  target_compile_options(sqlite_cpp_raii PRIVATE /W4 /permissive-)
else()
  target_compile_options(sqlite_c_example PRIVATE -Wall -Wextra -Wpedantic -Wconversion)
  target_compile_options(sqlite_cpp_raii PRIVATE -Wall -Wextra -Wpedantic -Wconversion)
endif()
