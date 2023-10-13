resource "python_exec" "main" {
    script = "get_token.py"
    args = "foo"
#    args = "<ARG1> <ARG2>....."
}

#   output "token" {
#     value =  python_exec.main.exec_py

#   }