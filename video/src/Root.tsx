import React from 'react';
import {Composition} from 'remotion';
import {Film} from './Film';
import {FilmV2} from './FilmV2';
import data from './content-v2.json';
export const Root = () => <><Composition id="WhosMeV2" component={FilmV2} durationInFrames={data.duration} fps={30} width={1920} height={1080}/><Composition id="WhosMe" component={Film} durationInFrames={3600} fps={30} width={1920} height={1080}/></>;
