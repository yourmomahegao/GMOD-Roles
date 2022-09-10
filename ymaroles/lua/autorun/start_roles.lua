if SERVER then
	include( "server/sv_roles.lua" )
	AddCSLuaFile( "client/cl_roles.lua" )
end

if CLIENT then
	include( "client/cl_roles.lua" )
end

print( "YMA FPS Roles loading done." )
print( "-----------------------" )