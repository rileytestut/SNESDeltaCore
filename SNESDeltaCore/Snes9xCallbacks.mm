//
//  Snes9xCallbacks.cpp
//  MeSNEmu
//
//  Created by Lucas Menge on 1/5/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#include <UIKit/UIKit.h>

#include "Snes9xCallbacks.h"

#include <sys/time.h>
#include <libgen.h>

#include "../SNES9X/snes9x.h"
#include "../SNES9X/memmap.h"
#include "../SNES9X/apu/apu.h"
#include "../SNES9X/conffile.h"
#include "../SNES9X/controls.h"
#include "../SNES9X/display.h"

#include "Snes9xMain.h"

#pragma mark Defines

#undef TIMER_DIFF
#define TIMER_DIFF(a, b) ((((a).tv_sec - (b).tv_sec) * 1000000) + (a).tv_usec - (b).tv_usec)

#pragma mark - External Forward Declarations

extern int SI_SoundOn;

// Delta
extern "C" void SNESRefreshScreen();

#pragma mark - Global Variables

struct timeval SI_NextFrameTime = { 0, 0 };
int SI_FrameTimeDebt = 0;
int SI_SleptLastFrame = 0;

#pragma mark - SNES9X Callbacks

void S9xExit ()
{
}

void S9xParsePortConfig(ConfigFile &a, int pass)
{
  
}

void S9xExtraUsage (void)
{
  
}

void S9xParseArg (char** a, int &b, int c)
{
  
}

const char* S9xGetDirectory (enum s9x_getdirtype dirtype)
{
  static int	index = 0;
  static char	path[4][PATH_MAX + 1];
  
  char	inExt[16];
  char	drive[_MAX_DRIVE + 1], dir[_MAX_DIR + 1], fname[_MAX_FNAME + 1], ext[_MAX_EXT + 1];
  
  index++;
  if (index > 3)
    index = 0;
  
  switch (dirtype)
  {
    case SNAPSHOT_DIR:		strcpy(inExt, ".frz");	break;
    case SRAM_DIR:			strcpy(inExt, ".srm");	break;
    case SCREENSHOT_DIR:	strcpy(inExt, ".png");	break;
    case SPC_DIR:			strcpy(inExt, ".spc");	break;
    case CHEAT_DIR:			strcpy(inExt, ".cht");	break;
    case BIOS_DIR:			strcpy(inExt, ".bio");	break;
    case LOG_DIR:			strcpy(inExt, ".log");	break;
    default:				strcpy(inExt, ".xxx");	break;
  }
  
  _splitpath(S9xGetFilename(inExt, dirtype), drive, dir, fname, ext);
  _makepath(path[index], drive, dir, "", "");
  
  int	l = strlen(path[index]);
  if (l > 1)
    path[index][l - 1] = 0;
  
  return (path[index]);
}

bool8 S9xDoScreenshot (int width, int height)
{
  return true;
}

const char* S9xStringInput (const char* s)
{
  return (NULL);
}

void S9xHandlePortCommand (s9xcommand_t cmd, int16 data1, int16 data2)
{
  return;
}

bool S9xPollAxis (uint32 id, int16* value)
{
  return (false);
}

void S9xToggleSoundChannel (int c)
{
  static int	channel_enable = 255;
  
  if (c == 8)
    channel_enable = 255;
  else
    channel_enable ^= 1 << c;
  
  S9xSetSoundControl(channel_enable);
}

bool S9xPollButton (uint32 id, bool* pressed)
{
  *pressed = false;
  return true;
}

bool8 S9xContinueUpdate (int width, int height)
{
  return (true);
}

bool S9xPollPointer (uint32 id, int16* x, int16* y)
{
  *x = *y = 0;
  
  return (true);
}

const char* S9xChooseFilename (bool8 read_only)
{
  return (NULL);
}

const char* S9xChooseMovieFilename (bool8 read_only)
{
  return (NULL);
}

void S9xSetPalette ()
{
  
}

bool8 S9xOpenSnapshotFile (const char* fname, bool8 read_only, STREAM* file)
{
  if (read_only)
  {
		if (0 != (*file = OPEN_STREAM(fname, "rb")))
      return (true);
  }
  else
  {
		if (0 != (*file = OPEN_STREAM(fname, "wb")))
      return (true);
  }
  
  return (false);
}

void S9xCloseSnapshotFile (STREAM file)
{
  CLOSE_STREAM(file);
}

void S9xMessage (int /* type */, int /* number */, const char* message)
{
  printf ("%s\n", message);
}

bool8_32 S9xInitUpdate ()
{
  //GFX.Screen = (uint8*) framebuffer16 + (640*8) + 64;
  
  return (TRUE);
}

bool8 S9xDeinitUpdate (int width, int height)
{
  // TODO clear Z buffer if not in fastsprite mode
    SNESRefreshScreen();
  
    return (TRUE);
}

const char* S9xGetFilename (const char* ex, enum s9x_getdirtype dirtype)
{
  static char filename [PATH_MAX + 1];
  char drive [_MAX_DRIVE + 1];
  char dir [_MAX_DIR + 1];
  char fname [_MAX_FNAME + 1];
  char ext [_MAX_EXT + 1];
  
  _splitpath (Memory.ROMFilename, drive, dir, fname, ext);
  //strcpy (filename, SIGetSnapshotDirectory());
  strcpy (filename, "");
  strcat (filename, SLASH_STR);
  strcat (filename, fname);
  strcat (filename, ex);
  return (filename);
}

//const char* S9xGetFilenameInc (const char* e)
const char* S9xGetFilenameInc (const char* inExt, enum s9x_getdirtype dirtype)
{
  S9xMessage (0,0,"get filename inc");
  //return e;
  return inExt;
}

void S9xSyncSpeed(void)
{
    if (Settings.SoundSync)
    {
        while (!S9xSyncSound())
        {
            usleep(0);
        }
    }
    
    if (Settings.DumpStreams)
    {
        return;
    }
    
    if (Settings.HighSpeedSeek > 0)
    {
        Settings.HighSpeedSeek--;
    }
    
    if (Settings.TurboMode)
    {
        if ((++IPPU.FrameSkip >= Settings.TurboSkipFrames) && !Settings.HighSpeedSeek)
        {
            IPPU.FrameSkip = 0;
            IPPU.SkippedFrames = 0;
            IPPU.RenderThisFrame = TRUE;
        }
        else
        {
            IPPU.SkippedFrames++;
            IPPU.RenderThisFrame = FALSE;
        }
        
        return;
    }
    
    static struct timeval	next1 = { 0, 0 };
    struct timeval			now;
    
    while (gettimeofday(&now, NULL) == -1) ;
    
    // If there is no known "next" frame, initialize it now.
    if (next1.tv_sec == 0)
    {
        next1 = now;
        next1.tv_usec++;
    }
    
    // If we're on AUTO_FRAMERATE, we'll display frames always only if there's excess time.
    // Otherwise we'll display the defined amount of frames.
    unsigned	limit = (Settings.SkipFrames == AUTO_FRAMERATE) ? (timercmp(&next1, &now, <) ? 10 : 1) : Settings.SkipFrames;
    
    IPPU.RenderThisFrame = (++IPPU.SkippedFrames >= limit) ? TRUE : FALSE;
    
    if (IPPU.RenderThisFrame)
        IPPU.SkippedFrames = 0;
    else
    {
        // If we were behind the schedule, check how much it is.
        if (timercmp(&next1, &now, <))
        {
            unsigned	lag = (now.tv_sec - next1.tv_sec) * 1000000 + now.tv_usec - next1.tv_usec;
            if (lag >= 500000)
            {
                // More than a half-second behind means probably pause.
                // The next line prevents the magic fast-forward effect.
                next1 = now;
            }
        }
    }
    
    // Delay until we're completed this frame.
    // Can't use setitimer because the sound code already could be using it. We don't actually need it either.
    while (timercmp(&next1, &now, >))
    {
        // If we're ahead of time, sleep a while.
        unsigned	timeleft = (next1.tv_sec - now.tv_sec) * 1000000 + next1.tv_usec - now.tv_usec;
        usleep(timeleft);
        
        while (gettimeofday(&now, NULL) == -1) ;
        // Continue with a while-loop because usleep() could be interrupted by a signal.
    }
    
    // Calculate the timestamp of the next frame.
    next1.tv_usec += Settings.FrameTime;
    if (next1.tv_usec >= 1000000)
    {
        next1.tv_sec += next1.tv_usec / 1000000;
        next1.tv_usec %= 1000000;
    }
}

const char* S9xBasename (const char* in)
{
  /*const char* p;
  
  S9xMessage (0,0,"s9x base name");
  
  if ((p = strrchr (f, '/')) != NULL || (p = strrchr (f, '\\')) != NULL)
    return (p + 1);
  
  return (f);*/
  
  static char	s[PATH_MAX + 1];
  
	strncpy(s, in, PATH_MAX + 1);
	s[PATH_MAX] = 0;
  
	size_t	l = strlen(s);
  
	for (unsigned int i = 0; i < l; i++)
  {
		if (s[i] < 32 || s[i] >= 127)
			s[i] = '_';
	}
  
	return (basename(s));
}

//};

bool8 S9xOpenSoundDevice (void)
{
  if(SI_SoundOn)
    return TRUE;
  else
    return FALSE;
}

void S9xAutoSaveSRAM (void)
{
	//since I can't sync the data, there is no point in even writing the data
	//out at this point.  Instead I'm now saving the data as the users enter the menu.
  SISaveSRAM();
	//sync();  can't sync when emulator is running as it causes delays
}

#pragma mark - OS-Related Path Manipulation

void _makepath (char* path, const char*, const char* dir,
                const char* fname, const char* ext)
{
	if (dir && *dir)
	{
		strcpy (path, dir);
		strcat (path, "/");
	}
	else
    *path = 0;
	strcat (path, fname);
	if (ext && *ext)
	{
		strcat (path, ".");
		strcat (path, ext);
	}
}

void _splitpath (const char* path, char* drive, char* dir, char* fname,
                 char* ext)
{
	*drive = 0;
  
	char* slash = strrchr (path, '/');
	if (!slash)
		slash = strrchr (path, '\\');
  
	char* dot = strrchr (path, '.');
  
	if (dot && slash && dot < slash)
		dot = NULL;
  
	if (!slash)
	{
		strcpy (dir, "");
		strcpy (fname, path);
		if (dot)
		{
			*(fname + (dot - path)) = 0;
			strcpy (ext, dot + 1);
		}
		else
			strcpy (ext, "");
	}
	else
	{
		strcpy (dir, path);
		*(dir + (slash - path)) = 0;
		strcpy (fname, slash + 1);
		if (dot)
		{
			*(fname + (dot - slash) - 1) = 0;
			strcpy (ext, dot + 1);
		}
		else
			strcpy (ext, "");
	}
}
