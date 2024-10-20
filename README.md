# Salesforce Code Interpreter - OpenAI Assistant Integration

This project demonstrates the integration of OpenAI Assistant's Code Interpreter into Salesforce Communities using Lightning Web Components (LWC). It enables seamless interaction with OpenAI's Assistant API, providing enhanced user experiences within Salesforce Communities. This project showcases how Salesforce and OpenAI's language model can be combined to create a code interpretation assistant that processes uploaded files.

## Overview

The Salesforce Code Interpreter project uses Lightning Web Components (LWC) along with Apex classes to integrate OpenAI's Code Interpreter. It interprets data in uploaded CSV files and provides visual or text-based output.

The core of this implementation facilitates conversations with OpenAI Assistant, manages chat threads, and allows users to view responses from the assistant in real time.

## Features

- **Chat Interface**: The LWC component creates a chat interface for interacting with the OpenAI Assistant. It supports real-time interaction, enabling a smooth conversation experience.
- **Real-time Preview**: Below the chat interface, there is a preview pane for images. When users request visual outputs like charts or graphs, they are displayed in this pane.

## Technical Stack

- **Salesforce Lightning Web Components (LWC)**: Builds the user interface for community users.
- **Apex Classes**: Manages API calls to OpenAI and handles Salesforce-specific operations like saving and managing content.
- **OpenAI API**: Requires an OpenAI API key to integrate the Assistant and Code Interpreter capabilities.
- **Salesforce Communities**: Implemented within Salesforce Communities, providing easy access for community users. Assumes familiarity with basic LWC and REST APIs.

## Project Structure

### Lightning Web Component (LWC)

The LWC is responsible for the front-end chat interface:

- **HTML Template**: Defines the chat structure, including input fields, chat logs, and buttons.
- **JavaScript Controller**: Manages user input, API calls to the Apex backend, and processes responses from OpenAI Assistant.
- **CSS Styles**: Defines the styling for a user-friendly chat experience.

### Apex Classes

The Apex classes handle server-side operations:

- **API Integration**: Methods to call OpenAI APIs, including creating new threads, sending user queries, and receiving responses.
- **Thread Management**: Handles chat thread creation, management, and termination.
- **File Handling**: Manages file content from OpenAI and saves it as Salesforce Content Versions.

### XML Configuration

The XML configuration file (`.xml`) exposes the LWC to different Salesforce pages, including App, Record, and Community pages. It also supports adding the Assistant ID dynamically using LWC properties in Salesforce App Builder.

## Key Code Walkthrough

### LWC Component (`OpenAIAssistant`)

- **HTML Template**: Defines the chat interface, including:
  - A header showing the assistant's name.
  - A chat log for displaying user and assistant messages.
  - Input fields and buttons for sending queries or ending the chat.
- **JavaScript (`OpenAIAssistant.js`)**:
  - **connectedCallback()**: Initializes the component and creates a new chat thread.
  - **handleButtonClick()**: Handles user queries, sends them to OpenAI, and processes the response.
  - **checkCompletionStatus()**: Recursively checks the status of code execution.
  - **getRunSteps()**: Retrieves intermediate steps of code execution for feedback.

### Apex Class (`ComponentsalesforceCodeInterpreter`)

- **createNewThread()**: Sends an HTTP POST request to OpenAI to create a new chat thread.
- **sendQueryToApi()**: Sends user queries to OpenAI and starts a code interpretation run.
- **checkRun()**: Checks the status of the assistant's execution.
- **getRunStep()**: Retrieves the latest step of code processing.
- **getImageUrl()**: Converts file responses from OpenAI to Salesforce Content Versions and generates a URL.

## Configuration

- **API Keys**: Update the `Meta_Assistant__mdt` custom metadata type with your OpenAI API key and endpoint.
- **Assistant Configuration**: Use XML configuration to set properties like `assistantID`, `assistHeader`, and `assistPlaceholder` to customize the assistant.

## Usage

1. **Start a Chat**: Community users can begin interacting with the assistant through the chat interface.
2. **Send Code for Interpretation**: Users can input code snippets for the assistant to execute and interpret.
3. **End Chat**: Users can end the chat, clearing conversation history.

## Limitations

- **API Rate Limits**: OpenAI API rate limits may affect responsiveness. Code Interpreter is more expensive that RAG as it charges based on session based. 
- **Error Handling**: Need to work on better error handling.

## Future Enhancements

- **Assistant Typing Animation**: Adding an animation to show when the assistant is analyzing or typing.
- **Graph Rendering Loader**: A loader or spinner to indicate when an image is being rendered.
- **Improved File Handling**: Instead of saving files in Salesforce, directly render blobs in the UI for certain use cases.

## Contributing

Contributions are welcome! Feel free to submit a pull request or open an issue to discuss any changes or improvements.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.

## Contact

For questions or issues, contact [kamal.thakur.dev16@gmail.com].
