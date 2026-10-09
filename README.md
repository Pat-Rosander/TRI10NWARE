# TRI10NWARE

A 2D platformer developed in **Godot 4.5.1** for a game jam.

## Requirements

Before getting started, make sure you have:

- **Godot Engine 4.5.1 (Standard Version)**
- **Git** (recommended for cloning the repository)
- A computer running Windows, macOS, or Linux

Download Godot 4.5.1 from the official release page:

[Godot 4.5.1 — Official Download](https://godotengine.org/download/archive/4.5.1-stable/)

The project uses GDScript, so the .NET/C# version of Godot is not required.

## Installation and Setup

### 1. Clone the Repository

Open your terminal (macOS/Linux) or PowerShell/Git Bash (Windows).

Navigate to the directory where you want to store the project, then run:

```bash
git clone https://github.com/Pat-Rosander/TRI10NWARE.git
```

Navigate into the cloned directory:

```bash
cd TRI10NWARE
```

Alternatively, download the repository directly from GitHub:

1. Click the green **Code** button on the repository page.
2. Select **Download ZIP**.
3. Extract the ZIP file to your desired location.

### 2. Import the Project into Godot

1. Launch **Godot 4.5.1**.
2. In the Godot Project Manager, click **Import**.
3. Navigate to your cloned or extracted `TRI10NWARE` folder.
4. Select the `project.godot` file.
5. Click **Import & Edit**.

Godot will open the project and automatically begin importing its assets.

**Important:** Allow Godot to finish importing resources before running the game for the first time.

### 3. Run the Game

Once the project opens in the Godot editor:

1. Click the **Run Project** button (▶) in the upper-right corner.
2. Alternatively, press **F5**.
3. Godot will launch the configured main scene.

To stop the game, close the game window or click the **Stop** button in the Godot editor.

You can also run an individual scene using **F6**.

## Controls

The following controls are configured in the project's Input Map:

| Action | Keyboard Input |
|---|---|
| Move Left | A / Left Arrow |
| Move Right | D / Right Arrow |
| Jump | Space |
| Dash | S |
| Switch | E |

Controls can be viewed or modified through **Project → Project Settings → Input Map**.

## Project Structure

```text
TRI10NWARE/
├── assets/            # Game sprites and other assets
├── levels/            # Level scenes and related resources
├── player/            # Player scene and movement scripts
├── project.godot      # Godot project configuration
├── icon.svg           # Project icon
└── README.md          # Project documentation
```

The `project.godot` file is essential for importing the project. Always select the repository's root directory when importing into Godot.

## Troubleshooting

### Project doesn't appear in Godot

Make sure you're importing the folder containing `project.godot`, rather than a subdirectory such as `player/` or `levels/`.

### Assets or textures are missing

Wait for Godot's initial asset import to finish. If problems persist, close and reopen the project.

### Scripts or scenes display errors

Verify you're using **Godot 4.5.1**. Earlier Godot versions may not support every feature used by this project.

Also make sure you have downloaded the complete repository, including all scenes, scripts, and asset folders.

### Game window is too small or doesn't scale correctly

Open **Project → Project Settings → Display → Window**.

Adjust the window mode, viewport dimensions, or stretch settings to suit your display.
