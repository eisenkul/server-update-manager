# Server Update Manager

**Author:** Ersin Isenkul  
**Email:** ersinisenkul@gmail.com  
**Version:** 1.0, Dec 25th, 2023

## Synopsis

This PowerShell script is designed to manage server updates and services on a list of servers.

## Description

The script provides a menu-driven interface for administrators to perform various tasks, including checking for updates, installing updates, viewing update status, managing services, and restarting servers on specific servers or all servers in the list. Servers in the list can be viewed, deleted, or new servers can be added to the list.

## Example

Example of how to use this script:

1. Run the script.
2. Enter the server list at the first run.
3. Choose an action from the menu.
4. Provide admin credentials when prompted.
5. Perform the selected action on the specified servers.

## Inputs

- You must enter the server list at the first use (Server01;Server02;Server03...).
- You can input servers to this server list if you want.
- The script prompts the user for admin credentials when necessary.

## Outputs

The script provides status messages and information about updates and services on the specified servers.

## Notes

This script relies on PowerShell remoting to perform actions on remote servers. Ensure that remoting is enabled and that the executing user has the necessary permissions.

## Component

Server Management

## Role

Administrator

## Functionality

- Checking for available updates on servers.
- Installing updates on servers.
- Viewing update status on servers.
- Retrieving and restarting services with stopped status and automatic start type on servers.
- Restarting servers from the list.
- Providing an interactive menu for users to choose and perform actions on servers.
