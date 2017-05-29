# Copyright 2017 Joseph Mansfield
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

include(CMakeParseArguments)

# Add a transform target that pipes the content of SOURCES through COMMAND.
#
#     add_transform(line_count COMMAND wc -l SOURCES file1 file2)
function(add_transform)
	set(many_value_args COMMAND SOURCES)
	cmake_parse_arguments(parsed_args "" "" "${many_value_args}" ${ARGN})

	list(LENGTH parsed_args_UNPARSED_ARGUMENTS unparsed_arguments_count)
	if(unparsed_arguments_count LESS 1)
		message(FATAL_ERROR "add_transform: Transform name required")
	endif()

	list(GET parsed_args_UNPARSED_ARGUMENTS 0 transform_name)

	set(source_files ${parsed_args_SOURCES})


	set(gen_dir ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/transform_gen/${transform_name})
	file(MAKE_DIRECTORY ${gen_dir})
	file(RELATIVE_PATH relative_gen_dir ${CMAKE_CURRENT_SOURCE_DIR} ${gen_dir})

	foreach(source_file ${source_files})
		get_filename_component(source_file_dir ${source_file} DIRECTORY)

		file(MAKE_DIRECTORY ${gen_dir}/${source_file_dir})
		add_custom_command(
			OUTPUT ${gen_dir}/${source_file}
			COMMAND cat ${CMAKE_CURRENT_SOURCE_DIR}/${source_file} | ${parsed_args_COMMAND} > ${gen_dir}/${source_file}
			DEPENDS ${source_file}
		)

		file(RELATIVE_PATH source_file_relative ${CMAKE_CURRENT_SOURCE_DIR} ${gen_dir}/${source_file})

		set(${transform_name}_gen_files ${${transform_name}_gen_files} ${source_file_relative})
	endforeach()

	set(${transform_name}_gen_files ${${transform_name}_gen_files} PARENT_SCOPE)
	set(${transform_name}_gen_dir ${relative_gen_dir} PARENT_SCOPE)

	add_custom_target(${transform_name} DEPENDS ${${transform_name}_gen_files})
endfunction(add_transform)

# Get transformed file targets for SOURCES from an existing transform target.
#
#     get_transformed(my_transform_target file1_transformed_target SOURCES file1)
function(get_transformed)
	set(many_value_args SOURCES)
	cmake_parse_arguments(parsed_args "" "" "${many_value_args}" ${ARGN})

	list(GET parsed_args_UNPARSED_ARGUMENTS 0 transform_name)
	list(GET parsed_args_UNPARSED_ARGUMENTS 1 output_var)

	set(source_files ${parsed_args_SOURCES})
	list(LENGTH source_files source_files_count)

	if(source_files_count LESS 1)
		set(${output_var} ${${transform_name}_gen_files} PARENT_SCOPE)
	else()
		foreach(source_file ${source_files})
			set(transformed_file ${${transform_name}_gen_dir}/${source_file})

			list(FIND ${transform_name}_gen_files ${transformed_file} index)
			if(index EQUAL -1)
				message(FATAL_ERROR "get_transformed: No transformed file for ${source_file}")
			endif()

			set(output ${output} ${transformed_file})
		endforeach()

		set(${output_var} ${output} PARENT_SCOPE)
	endif()
endfunction(get_transformed)
