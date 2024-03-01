# Analysis of the problem

## Description of the problem

Project idea: A basic microblogging platform. The end users of the application will be other students in the Computing Science class or club, to allow them to share thoughts and ideas, and post updates to projects they're working on.

The platform will be a website with a frontend written in HTML and CSS for their compatibility with nearly all devices, and a backend written in Luau, as it's the language I'm most familiar with.

## UML use case diagram

```plantuml
@startuml
left to right direction
skinparam dpi 300
' increase aspect ratio
skinparam DefaultFontName "Readex Pro Deca"

:Registered user: as ruser
:New user: as user

rectangle {
	usecase "Log in" as login
	usecase "Register\naccount" as register
	usecase "Authenticate\nuser" as auth
	usecase "Input\nvalidation" as input

	usecase "Create post" as createpost
	usecase "View posts" as viewposts
	usecase "Search post" as searchpost
	usecase "View profile" as viewprofile
	usecase "Log out" as logout

	login ..>> auth: <font size=11><<include>></font>
	register ..>> auth: <font size=11><<include>></font>

	register ..>> input: <font size=11><<include>></font>
	login ..>> input: <font size=11><<include>></font>

	rectangle Database {
		' should have session table, user table, and post table
		database "Sessions table" as sessions #pink
		database "Users table" as users #lightgreen
		database "Posts table" as posts #lightblue

		login -- sessions
		register -- users
		createpost -- posts
		viewposts -- posts
		searchpost -- posts
		viewprofile -- users
		viewprofile -- posts
		logout -- sessions
	}
}

ruser ->> user

user -- register
ruser -- login
ruser -- createpost
ruser -- searchpost
ruser -- viewposts
ruser -- viewprofile
ruser -- logout
@enduml
```
