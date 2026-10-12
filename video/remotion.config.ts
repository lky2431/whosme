import {existsSync} from 'node:fs';
import {Config} from '@remotion/cli/config';

const windowsChrome = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
if (process.platform === 'win32' && existsSync(windowsChrome)) {
  Config.setBrowserExecutable(windowsChrome);
}
Config.setOverwriteOutput(true);
