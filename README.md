<center>
<h1>Ray Music Player (RayMP)</h1>
</center>

<p align="center">
  <img src="./assets/logo.jpg" width="350" height="350"/>
</p>

1. CLI music player written in pure C
2. contain a beatiful ui 
3. simple to use

# Features

<ul> 
  <li>File explorer: allows users to navigate through directories and select music files to play
  </li> 
  <li>Music player: plays music files using the Miniaudio library
  </li> 
  <li>UI components: provides a user-friendly interface for interacting with the music player and file explorer
  </li> 
  <li>Keyboard shortcuts: supports various keyboard shortcuts for controlling the playback, navigating through directories, and interacting with the UI
  </li> 
</ul> 

# Quick Start
```console
$ gcc -o main main.c -lm -lpthread # simple
$ ./main
```

<h1>Music Player with File Explorer and UI Components</h1>
<p>This is a C program that implements a music player with a file explorer and user interface (UI) components. The program allows users to navigate through directories, play music files, and control the playback using various keyboard shortcuts.
</p> 
<h2>Keyboard Shortcuts</h2> 
<ul> 
  <li>q: quit the program</li> 
  <li>u: update the UI</li> 
  <li>e: toggle the file explorer</li> 
  <li>f: add a song to favorites (not implemented)</li>
  <li>SPACE: pause or play music</li> 
  <li>+ and -: adjust the volume</li> 
  <li>j and k: move the cursor up or down</li> 
  <li>&gt; and &lt;: move to the next or previous song</li>
  <li>i: change the UI style</li> 
  <li>a: open favorite songs (not implemented)</li> 
  <li>s: search for songs on the local device (not implemented)</li> 
  <li>S: search for songs on the internet (not implemented)
  </li> 
  <li>? : show help list (not implemented)</li> 
  <li>TAB: change the status</li> 
</ul> 

# Note 
<p>this software only tested on linux (Debian) if you see this software is useful , you can help to create a windows version or other OS versions , check [contribute](https://github.com/abdorayden/raymp/CONTRIBUTIONS.md) file
</p>
