def process_command(command):
    if command == "-about":
        print("This is the about section.")
    elif command == "-help":
        print("Available commands: -about, -help, -clear")
    elif command == "-clear":
        print("Clearing the screen...")
    else:
        print("Invalid command.")
    print("-----------------------------")

# Example usage
process_command("-about")
process_command("-help")
process_command("-clear")
process_command("-invalid")