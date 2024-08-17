# PWSH_BatchConverter_ffmpeg
This is a Tool made with Powershell to convert Videos in batch to your desired Parameters.

You define Input and output Dir and start the conversion with a Template File.

And the best thing: It has also a **Status Bar**! ;)



[![preview](https://raw.githubusercontent.com/DerHary/PWSH_BatchConverter_ffmpeg/main/additional_files/preview.webp "preview")](https://raw.githubusercontent.com/DerHary/PWSH_BatchConverter_ffmpeg/main/additional_files/preview.webp "preview")



## Why this?
The inspiration for this was, that i dont want to convert my Videos with clumpy Frontends.

So my first intent was to create the Batch conversion via Scripts.

I had one Script for every Format/Quality that i ran in classic blue Powershell.

But i was searching for something that is showing me the Progress, of the actual File and how much files are still to process.

I found different things, but the most Progress showing tools are for Linux and/or have a lot of dependencies.

So i started to play and here we have the result :)


## What is required to use it?
In general, not that much.
**Actual Requirements:**
- NVIDIA GPU for using hwaccel cuda - thats what its made for
- ffmpg installed and defined in PATH or at least directly call-able with "ffmpg"
- Powershell (tested it with PWSH 7.4)