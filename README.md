# ZeroTierController-PowerShell

[![CI](https://github.com/alexdelifer/ZeroTierController-PowerShell/actions/workflows/main.yml/badge.svg)](https://github.com/alexdelifer/ZeroTierController-PowerShell/actions/workflows/main.yml)

A PowerShell library to interact with the ZeroTier Network Controller API

I was surprised nobody else had already tackled this, this is a great way to get started talking to REST APIs.
This is basically my first real PowerShell module, let me know if I can do anything better.

## TODO

- ~~Linux / macOS support~~ Thanks OvrAp3x
- ~~GitHub Actions Workflow to publish automatically~~ Thanks OvrAp3x
- Get/Set/Add/Remove -ZeroTierUser
- New-ZTNetwork (The API seems broken on this front...)
- Help documentation...

## Getting Started

1. Get an API Token from [ZeroTier](https://my.zerotier.com/account)
1. Install the Module:  

    ```PowerShell
    Install-Module -Name ZeroTierController 
    ```

1. Import the Module:  

    ```PowerShell
    Import-Module -Name ZeroTierController
    ```

1. Set the API token using the following command.

    ```PowerShell
    Set-ZTToken -Token "YOUR_API_KEY_HERE"
    ```

## Commands

- `Set-ZTToken`
- `Get-ZTStatus`
- `Get-ZTNetwork`
- `Set-ZTNetwork`
- `Get-ZTMember`
- `Set-ZTMember`
- `Enable-ZTMember #(Shortcut for Set-ZTMember -Authorized $True)`
- `Disable-ZTMember #(Shortcut for Set-ZTMember -Authorized $False)`
- `Add-ZTMember`
- `Remove-ZTMember`

## Usage

I did my best to make these cmdlets work like the builtin Windows cmdlets.
They show what I consider to be the most relevant 4 properties by default.
You can pipe whatever you want between them and everything should "just work".

You'll notice on both the Network and Member objects, there's a Config nested object that holds more detailed fields about the object. I've included parameters to Set-ZTMember and Set-ZTNetwork to make setting those easier. Otherwise you'd need to use ``` -Config @{Authorized=$False} ``` to deauth instead of ``` -Authorized $False ```, so both are valid and the latter takes precedence.

### Get All Networks

```powershell
# Provide no -Id to list all networks
PS > Get-ZTNetwork

Id               Description                         OnlineMemberCount AuthorizedMemberCount
--               -----------                         ----------------- ---------------------
ffffffffffffffff Private Network                                    83                   274
aaaaaaaaaaaaaaaa Test123                                             1                     2
```

### Get All Members From a Network

```powershell
# You can pipe the Id from Get-ZTNetwork into Get-ZTMember
# Provide no -NodeID to get all members
PS > Get-ZTNetwork -Id aaaaaaaaaaaaaaaa | Get-ZTMember

NodeId     Description Name       Online
------     ----------- ----       ------
aaaaaaaaaa test123     DeliferA    False
bbbbbbbbbb             Test         True
cccccccccc             Cloud       False
```

### Show a Single Member's Properties

```powershell
# Equivalent inputs to check a Node's object
PS > Get-ZTNetwork -Id aaaaaaaaaaaaaaaa | Get-ZTMember -Node aaaaaaaaaa | Select-Object *

PS > Get-ZTMember -Id aaaaaaaaaaaaaaaa -Node aaaaaaaaaa | Select-Object *

Id                  : aaaaaaaaaaaaaaaa-aaaaaaaaaa
Type                : Member
Clock               : 1608598939426
NetworkId           : aaaaaaaaaaaaaaaa
NodeId              : aaaaaaaaaa
ControllerId        : aaaaaaaaaa
Hidden              : False
Name                : DeliferA
Online              : False
Description         : test123
# Config is a nested object, there a special parameters to set these,
# you may also set them directly by $obj.Config.Authorized.
Config              : @{ActiveBridge=False; Address=aaaaaaaaaa; Authorized=True; Capabilities=; CreationTime=1608598939426; Id=aaaaaaaaaa;
                      Identity=aaaaaaaaaa:0:aaaaaaaaaa; IpAssignments=System.Object[];
                      LastAuthorizedTime=1608598939426; LastDeauthorizedTime=1608598939426; NoAutoAssignIps=False; Nwid=aaaaaaaaaaaaaaaa; Objtype=member; RemoteTraceLevel=0; RemoteTraceTarget=; Revision=13; Tags=;    
                      VMajor=1; VMinor=4; VRev=6; VProto=10}
LastOnline          : 1608598939426
PhysicalAddress     : 1.1.1.1
PhysicalLocation    :
ClientVersion       : 1.4.6
ProtocolVersion     : 10
SupportsRulesEngine : True
```

### Set a Node Property

```powershell
# Equivalent inputs to set a node's description and unauthorize
PS > $member = Get-ZTNetwork -Id aaaaaaaaaaaaaaaa | Get-ZTMember -Node aaaaaaaaaa
PS > $member | Set-ZTMember -Authorized $False -Description "test555"

PS > Set-ZTMember -Id aaaaaaaaaaaaaaaa -Node aaaaaaaaaa -Authorized $False -Description "test555"

Id                  : aaaaaaaaaaaaaaaa-aaaaaaaaaa
Type                : Member
Clock               : 1608598939426
NetworkId           : aaaaaaaaaaaaaaaa
NodeId              : aaaaaaaaaa
ControllerId        : aaaaaaaaaa
Hidden              : False
Name                : DeliferA
Online              : False
Description         : test555
Config              : @{ActiveBridge=False; Address=aaaaaaaaaa; Authorized=False; Capabilities=; CreationTime=1608598939426; Id=aaaaaaaaaa;
                      Identity=aaaaaaaaaa:0:aaaaaaaaaa; IpAssignments=System.Object[];
                      LastAuthorizedTime=1608598939426; LastDeauthorizedTime=1608598939426; NoAutoAssignIps=False; Nwid=aaaaaaaaaaaaaaaa; Objtype=member; RemoteTraceLevel=0; RemoteTraceTarget=; Revision=13; Tags=;    
                      VMajor=1; VMinor=4; VRev=6; VProto=10}
LastOnline          : 1608598939426
PhysicalAddress     : 1.1.1.1
PhysicalLocation    :
ClientVersion       : 1.4.6
ProtocolVersion     : 10
SupportsRulesEngine : True

```

### Using custom controller (self hosted)

Grab your authtoken from the controllers authtoken.secret

```powershell

PS > $zturl="http://yourcontrollerurl/api"

```


## References

[ZeroTier API Help](https://my.zerotier.com/help/api)
