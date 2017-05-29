# CMake Transform

CMake Transform is a collection of CMake functions for transforming files by piping them through a command.

## Usage

To add a transform target that will transform a list of source files by piping their content through a command:

    add_transform(<transform_name>
      COMMAND <command>
      SOURCES <files>...)

This also creates targets for each transformed file. To extract the names of the transformed file targets:

    get_transformed(<transform_name> <output_variable>
      SOURCES <files>...)

## Example

Given a text file `test.txt`:

    The old man said "GREETING" to the dog. The dog responded in kind: "GREETING". 

We can create a transform target in our `CMakeLists.txt` that substitutes the text `GREETING` with `Hello` and then, for demonstration purposes, add a post-build command that prints the transformed file contents:

    include(transform.cmake)

    set(input_file test.txt)

    add_transform(substitute
      COMMAND sed -e 's/GREETING/Hello/g'
      SOURCES ${input_file})

    get_transformed(substitute transformed_test_file
      SOURCES ${input_file})
    
    add_custom_command(
      TARGET substitute
      POST_BUILD
      COMMAND cat ${CMAKE_CURRENT_SOURCE_DIR}/${transformed_test_file}) 

If we then run `cmake` on the directory with these files and then `make substitute`, we see the following output:

    Scanning dependencies of target substitute
    [100%] Generating CMakeFiles/transform_gen/substitute/test.txt
    The old man said "Hello" to the dog. The dog responded in kind: "Hello".
    [100%] Built target substitute
