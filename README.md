# Getting file version of PE-32 EXE files

This small console utility takes as argument a path to EXE file (in Windows PE-32 format) and prints to STDOUT the file version from resource section (4 numbers delimited by dot)

I personally use this tool to implement auto-update of my desktop applications - the application sends a HTTP request to a REST API endpoint which invokes the tool (in a Linux environment) to get the version of the most recently deployed EXE. Then the application compares the response with its own version - and if it determines that there is a new version, it downloads the newer EXE and performs the auto-update.
