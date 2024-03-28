# Evaluation of the solution

The initial goal of the project was to create a basic microblogging platform, where other students could post and view posts on a simple website to share ideas and thoughts or post updates to their own projects. I believe that the project has been successful in meeting this goal, as it has implemented all required features and has met all the functional and end-user requirements specified in the design section.

## Meeting requirements specification

The results of testing with both unit tests and manual test tables have shown that the implementation of the solution meets all original functional and end-user requirements. Completed requirements include:

-   Use of a database to store user data, sessions, and posts
-   Navigation bar for easy navigation, available on all pages
-   Validation of all user input to prevent attacks on the login, registration, post creation, and search forms
-   Registration of user accounts with storage of usernames and passwords in a database table, showing a helpful error message if the username is invalid or already taken
-   Login system that checks user credentials against the database and creates a session if correct, showing a helpful error message if incorrect
-   Search functionality for finding posts by content, showing a helpful error message if the search query is empty
-   Homepage for viewing recent posts in reverse chronological order
-   Profile page for viewing recent posts by a specific user
-   Easy navigation between all pages, including different user profile pages

## Results of testing

The results of the tests showed that most features were working as expected, and that any issues were able to be resolved with minor changes to the code. The addition of client-side validation to the HTML forms was also successful, improving the user experience by providing instant feedback when a form was submitted with invalid data.

## Future maintainability

Use of modular functions, UI components, clear variable names, inline comments and doc-comments (comments at the top of a function explaining what it does, highlighted in the editor), formatting tools, version control commits with clear and concise messages, type annotations in the codebase, and the documentation you are reading right now all contribute to improving the maintainability of the project.

However, the project uses a fair amount of non industry-standard tooling and custom solutions for problems that could more easily be solved in other languages. The structure of the custom routing system is familiar to me as it was inspired by other popular web frameworks, but it may seem convoluted or unnecessary to others. Use of a custom templating language may also have been unnecessary, as it could have been replaced with a more standard solution like simple string interpolation or a more popular and well-known templating language. (In truth, I was halfway through implementing a custom programming language for the project before abandoning the idea.)

While these solutions were helpful as a learning experience during the project, they may not be the best choice for long term maintainability, as lack of familiarity, prior experience, or documentation on specific features could make it difficult for others to understand or modify the project in the future.

## Robustness

Use of input validation, good error handling, and unit tests increase the project's robustness against common attacks and errors. Unit tests can be re-run after modifying a function to ensure that it still works as expected, and error handling will display an error page with a corresponding HTTP status code if an error occurs during the request, rather than crashing the server and causing the request to time out.
