# Implementation of the solution

## New skills researched and developed

For a working implementation of the finished application, I had to research and apply some skills that were not part of the Advanced Higher course.

Unlike some languages or server-side frameworks like PHP, Python, or Ruby on Rails, the Luau language, due to its sandboxed nature, does not provide built-in functions or support for dealing with HTTP requests or interacting with the filesystem. To compensate for this, the Lune runtime provides `net` and `fs` modules, but these modules have limited ability to create the necessary server-side functionality on their own.

For the backend of the application, I had to implement a custom filesystem-based router that transforms pages from the `routes` directory into functions that can be called by requests to the server. The `public` directory holds miscellaneous files like icons and stylesheets which are loaded by the browser when the user visits the site.

For the frontend, a parser for a basic templating language was created. The parser takes advantage of Luau's string interpolation functions, allowing me to write Luau and HTML in the same file (these files are specified with a `.ltmp` extension in the project repository), and turning it into a function that can be called and returned as a string by the server. It transforms the following template:

```ltmp
{#
	local fw = require "framework"
	print "loading page..."
#}

You are {username}

{# for num = 1, 5 do #}
	{num}
{# end #}
```

into the following function:

```luau
function()
	local _rendered = ""
	print "loading page..."
	_rendered ..= `You are {username}\n\n`
	for num = 1, 5 do
		_rendered ..= `{num}\n`
	end
	return _rendered
end
```

If future performance or lower resource usage is required in the future, these frontend and backend functions could be trivially loaded as coroutines and ran concurrently on the same thread or utilising multiple threads through the use of actors.

For the database, a very simple proxy server was used to handle incoming requests from the website and run them as queries on the database. It was written in Typescript, and was required because Luau does not have built-in support for MySQL or other database systems.

I have used systems like server-side routing, templating, and database connections in other projects, but this was the first time I had to implement them from scratch in a language that did not have built-in support for them. This was a valuable learning experience, giving me a better understanding and insight into the inner workings of these systems.

Another skill developed was during the implementation of the Advanced Higher algorithms required, namely bubble sort, insertion sort, and binary search. These algorithms were originally designed to be implemented only for number types, though as the system deals with lots of text, they needed to be modified to work with string types as well. Due to the Luau language naturally overloading the greater-than and less-than operators to compare strings based on alphabetical ordering, the logic for comparing strings did not need to change.

However, this changed the types of data each algorithm could take as arguments and return, meaning they no longer had correct type annotations. To fix this, I had to research and implement generic types, which are natively supported in Luau. This allowed the algorithms to be written to accept any supported type and return the same type, which made them more flexible and reusable.

## Ongoing testing and issues resolved

During testing, it was found that it needed to support page actions, allowing the same page to accept requests of multiple types, such as GET and POST for pages with forms. This was implemented by adding an `page.actions` field to the table returned by every page, and allowing the router to call the correct action based on a query parameter in the request, otherwise using the `default` action.

A second issue that occurred was due to the same code for posts being reused on many pages across the site, however the code couldn't be easily extracted into a function because of the frontend using a templating system. To solve this, the templating system was modified with a component system, exposed as a Load function, that allowed template files in the `/components` directory to be loaded and reused in other templates on multiple pages, increasing modularity and reducing code duplication.

Another issue was the potential usability or performance problems when loading huge lists of posts. To solve this, posts were cut to a maximum of 10 on the home and profile pages, though the search system can still be used to find older posts. Extremely long usernames would also cause issues with storing them in the database and displaying them on the site, so a username length of between 3 and 20 characters was enforced.

![Error message displayed when a username is too long](screenshots/Register-input3.png)

A final issue was the lack of syntax highlighting for custom Luau templating files in the text editor used to write the code, Visual Studio Code. This was solved by creating a custom syntax highlighting extension for the `.ltmp` file extension, which was simple as it only had to embed existing Luau and HTML syntax highlighting, delimited by the `{# #}` and `{ }` characters.
