#!/usr/bin/env python

import argparse
from urllib.parse import urlparse
from urllib.parse import parse_qs
import os
import logging
import ytmusicapi
import youtube_dl
import eyed3
import eyed3.id3
import datetime
from PIL import Image
from urllib.request import urlopen
import io
import re
import unicodedata
import sys


def getargs():
    parser = argparse.ArgumentParser()
    parser.add_argument("url", metavar="url", nargs="+",
                        help="url of artist, album, or song from youtube music.")
    parser.add_argument("-f", "--folder", metavar="folder", default=".",
                        help="Output directory to save into.")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Print more.")
    parser.add_argument("-o", "--overwrite", action="store_true",
                        help="Overwrite songs if they already exist.")

    args = parser.parse_args()

    for url in args.url:
        if not urlparse(url).netloc.endswith("youtube.com"):
            raise Exception("unknown url {}".format(url))
    if not os.path.isdir(args.folder):
        raise Exception("folder not found")

    return args


class DownloadError(Exception):
    pass


class Downloader():
    def __init__(self, args):
        self.folder = args.folder.rstrip("/")
        self.overwrite = args.overwrite
        self.ytm = ytmusicapi.YTMusic(
            os.path.join(sys.path[0], "secrets/ytmusic_headers_auth.json"))

    def _videoInfo(self, videoID):
        try:
            self._videoInfoCache
        except:
            self._videoInfoCache = {}

        if videoID in self._videoInfoCache:
            return self._videoInfoCache[videoID]

        try:
            self._videoInfoCache[videoID] = self.ytm.get_song(videoID)
        except:
            raise DownloadError("video not found {}".format(videoID))

        return self._videoInfoCache[videoID]

    def _searchInfo(self, videoID):
        try:
            self._searchInfoCache
        except:
            self._searchInfoCache = {}

        if videoID in self._searchInfoCache:
            return self._searchInfoCache[videoID]

        videoInfo = self._videoInfo(videoID)
        if not videoInfo:
            self._searchInfoCache[videoID] = None
            return self._searchInfoCache[videoID]

        searchQuery = "{} {}".format(
            videoInfo["videoDetails"]["title"], videoInfo["videoDetails"]["author"])

        searchResults = self.ytm.search(searchQuery, filter="songs", limit=20)
        if len(searchResults) == 0:
            self._songInfoCache[videoID] = None
            return self._songInfoCache[videoID]
        else:
            for result in searchResults:
                if result["videoId"] == videoID:
                    self._searchInfoCache[videoID] = result
                    self._searchInfoCache[result["videoId"]] = result
                    return self._searchInfoCache[videoID]

        self._searchInfoCache[videoID] = searchResults[0]
        self._searchInfoCache[result["videoId"]] = searchResults[0]
        return self._searchInfoCache[videoID]

    def _songInfo(self, videoID):
        try:
            self._songInfoCache
        except:
            self._songInfoCache = {}

        if videoID in self._songInfoCache:
            return self._songInfoCache[videoID]

        searchInfo = self._searchInfo(videoID)
        if not searchInfo:
            self._songInfoCache[videoID] = None
            return self._songInfoCache[videoID]

        self._songInfoCache[videoID] = self._videoInfo(searchInfo["videoId"])
        return self._songInfoCache[videoID]

    def _artistInfo(self, artistID):
        try:
            self._artistInfoCache
        except:
            self._artistInfoCache = {}

        if artistID in self._artistInfoCache:
            return self._artistInfoCache[artistID]

        try:
            self._artistInfoCache[artistID] = self.ytm.get_artist(artistID)
        except:
            self._artistInfoCache[artistID] = None

        return self._artistInfoCache[artistID]

    def _albumInfo(self, videoID):
        try:
            self._albumInfoCache
        except:
            self._albumInfoCache = {}

        if videoID in self._albumInfoCache:
            return self._albumInfoCache[videoID]

        searchInfo = self._searchInfo(videoID)
        if not searchInfo:
            self._albumInfoCache[videoID] = None
            return self._albumInfoCache[videoID]

        try:
            self._albumInfoCache[videoID] = self.ytm.get_album(
                searchInfo["album"]["id"])
        except:
            self._albumInfoCache[videoID] = None

        return self._albumInfoCache[videoID]

    # def channel(self, channelID):
    #     songs = []

    #     channelInfo = self._artistInfo(channelID)
    #     logging.debug("finished feching artist info")

    #     if "songs" in channelInfo and channelInfo["songs"]:
    #         songsList = []
    #         if "results" in channelInfo["songs"] and channelInfo["songs"]["results"]:
    #             songsList = channelInfo["songs"]["results"]
    #         if "browseId" in channelInfo["songs"] and channelInfo["songs"]["browseId"]:
    #             songsInfo = self.ytm.get_playlist(
    #                 channelInfo["songs"]["browseId"], 10000)
    #             songsList = songsInfo["tracks"]
    #         for song in songsList:
    #             songs.append(song["videoId"])
    #     logging.debug("finished feching artist songs")

    #     if "albums" in channelInfo and channelInfo["albums"]:
    #         albumsList = []
    #         if "results" in channelInfo["albums"] and channelInfo["albums"]["results"]:
    #             albumsList = channelInfo["albums"]["results"]
    #         if "browseId" in channelInfo["albums"] and channelInfo["albums"]["browseId"]:
    #             albumsInfo = self.ytm.get_artist_albums(channelInfo["albums"]["browseId"],
    #                                                     channelInfo["albums"]["params"])
    #             albumsList = albumsInfo
    #         for album in albumsList:
    #             albumInfo = self._albumInfo(album["browseId"])
    #             if not albumInfo:
    #                 break
    #             for song in albumInfo["tracks"]:
    #                 songs.append(song["videoId"])
    #     logging.debug("finished feching artist albums")

    #     if "singles" in channelInfo and channelInfo["singles"]:
    #         singlesList = []
    #         if "results" in channelInfo["singles"] and channelInfo["singles"]["results"]:
    #             singlesList = channelInfo["singles"]["results"]
    #         if "browseId" in channelInfo["singles"] and channelInfo["singles"]["browseId"]:
    #             singlesInfo = self.ytm.get_artist_albums(channelInfo["singles"]["browseId"],
    #                                                      channelInfo["singles"]["params"])
    #             singlesList = singlesInfo
    #         for single in singlesList:
    #             singleInfo = self._albumInfo(single["browseId"])
    #             if not singleInfo:
    #                 break
    #             for song in singleInfo["tracks"]:
    #                 songs.append(song["videoId"])
    #     logging.debug("finished feching artist singles")

    #     logging.info("finished fetching songs")
    #     self.songs(songs)

    # def album(self, id):
    #     songs = []

    #     albumInfo = self._albumInfo(id)
    #     for song in albumInfo["tracks"]:
    #         songs.append(song["videoId"])

    #     logging.info("finished fetching songs")
    #     self.songs(songs)

    # def playlist(self, id):
    #     songs = []

    #     with youtube_dl.YoutubeDL({
    #         "extract_flat": True,
    #         "quiet": True,
    #     }) as ydl:
    #         playlist = ydl.extract_info(
    #             "https://music.youtube.com/playlist?list={}".format(id), download=False)
    #         for song in playlist["entries"]:
    #             songs.append(song["id"])

    #     logging.info("finished fetching songs")
    #     self.songs(songs)

    # def songs(self, songs):
    #     songsCopy = songs
    #     songs = []
    #     for song in songsCopy:
    #         if song not in songs:
    #             songs.append(song)

    #     logging.debug("downloading song list: {}".format(songs))

    #     for index in range(len(songs)):
    #         logging.info("downloading song {} of {}".format(
    #             index + 1, len(songs)))
    #         try:
    #             self.song(songs[index], True)
    #         except DownloadError as error:
    #             logging.warning("download failed: {}".format(error))

    def song(self, videoID, preferSong=False):
        logging.info("downloading song: {}".format(id))

        # videoInfo = self._songInfo(id)
        # try:
        #     id = videoInfo["videoDetails"]["videoId"]
        # except:
        #     raise DownloadError("video not found {}".format(id))
        # logging.debug("basicInfo: {}".format(videoInfo))

        # searchQuery = "{} {}".format(
        #     videoInfo["videoDetails"]["title"], videoInfo["videoDetails"]["author"])
        # logging.debug("searchQuery: {}".format(searchQuery))

        # searchInfo = None
        # searchResults = self.ytm.search(searchQuery, filter="songs", limit=20)
        # if len(searchResults) == 0:
        #     if preferSong:
        #         raise DownloadError("song not found {}".format(searchQuery))
        # else:
        #     for result in searchResults:
        #         if result["videoId"] == id:
        #             searchInfo = result
        #             break
        #     else:
        #         searchInfo = searchResults[0]
        # logging.debug("searchInfo: {}".format(searchInfo))

        # songInfo = basicInfo
        # if searchInfo and searchInfo["videoId"] != songInfo["videoId"]:
        #     songInfo = self._songInfo(searchInfo["videoId"])
        # logging.debug("songInfo: {}".format(songInfo))

        # albumInfo = None
        # albumSongInfo = None
        # if searchInfo and "album" in searchInfo and searchInfo["album"]:
        #     albumInfo = self._albumInfo(searchInfo["album"]["id"])
        #     if albumInfo and "tracks" in albumInfo and albumInfo["tracks"]:
        #         for albumSong in albumInfo["tracks"]:
        #             if albumSong["title"] == searchInfo["title"]:
        #                 albumSongInfo = albumSong
        #                 break
        # logging.debug("albumInfo: {}".format(albumInfo))
        # logging.debug("albumSongInfo: {}".format(albumSongInfo))

        # songUrl = "https://music.youtube.com/watch?v={}"
        # if preferSong and songInfo:
        #     songUrl = songUrl.format(searchInfo["videoId"])
        # else:
        #     songUrl = songUrl.format(id)
        # logging.debug("songUrl: {}".format(songUrl))

        # artists = []
        # artistIds = []
        # if searchInfo and "artists" in searchInfo and searchInfo["artists"]:
        #     for artist in searchInfo["artists"]:
        #         if artist["id"] not in artistIds:
        #             try:
        #                 artistInfo = self._artistInfo(artist["id"])
        #             except:
        #                 name = artist["name"]
        #             else:
        #                 name = artistInfo["name"]
        #             if name not in artists:
        #                 artists.append(name)
        #                 artistIds.append(artist["id"])
        #     if "artists" in songInfo and songInfo["artists"]:
        #         for artist in songInfo["artists"]:
        #             if artist not in artists:
        #                 artists.append(artist)
        # elif "artists" in basicInfo and basicInfo["artists"] and len(basicInfo["artists"]) > 0:
        #     artists = basicInfo["artists"]
        # elif "author" in basicInfo:
        #     artists = [basicInfo["author"]]
        # logging.debug("artists: {}".format(artists))

        # albumArtist = None
        # if len(artists) > 0:
        #     albumArtist = artists[0]
        # logging.debug("albumArtist: {}".format(albumArtist))

        # artistUrl = None
        # if len(artistIds) > 0:
        #     artistUrl = "https://music.youtube.com/channel/{}".format(
        #         artistIds[0])
        # elif "channelId" in basicInfo:
        #     artistUrl = "https://music.youtube.com/channel/{}".format(
        #         basicInfo["channelId"])
        # logging.debug("artistUrl: {}".format(artistUrl))

        # album = None
        # if albumInfo and "title" in albumInfo:
        #     album = albumInfo["title"]
        # elif searchInfo and "album" in searchInfo and searchInfo["album"]:
        #     album = searchInfo["album"]["name"]
        # logging.debug("album: {}".format(album))

        # albumArt = None
        # if albumInfo and "thumbnails" in albumInfo and albumInfo["thumbnails"] and len(albumInfo["thumbnails"]) > 0:
        #     albumInfo["thumbnails"].sort(
        #         key=lambda art: art["width"], reverse=True)
        #     albumArt = albumInfo["thumbnails"][0]["url"]
        # elif "thumbnail" in basicInfo and basicInfo["thumbnail"] and "thumbnails" in basicInfo["thumbnail"] and basicInfo["thumbnail"]["thumbnails"] and len(basicInfo["thumbnail"]["thumbnails"]) > 0:
        #     basicInfo["thumbnail"]["thumbnails"].sort(
        #         key=lambda art: art["width"], reverse=True)
        #     albumArt = basicInfo["thumbnail"]["thumbnails"][0]["url"]
        # logging.debug("albumArt: {}".format(albumArt))

        # trackNum = None
        # if albumSongInfo and "index" in albumSongInfo:
        #     trackNum = albumSongInfo["index"]
        # tracksNum = None
        # if albumInfo and "trackCount" in albumInfo:
        #     tracksNum = albumInfo["trackCount"]
        # track = (trackNum, tracksNum)
        # logging.debug("trackNum: {}".format(trackNum))

        # releaseDate = None
        # if albumInfo and "releaseDate" in albumInfo and albumInfo["releaseDate"]:
        #     releaseDate = "{}".format(albumInfo["releaseDate"]["year"])
        # elif songInfo and "release" in songInfo:
        #     try:
        #         date = datetime.datetime.strptime(
        #             songInfo["release"], "%Y-%m-%d")
        #         releaseDate = date.strftime("%Y")
        #     except:
        #         pass
        # elif "release" in basicInfo:
        #     try:
        #         date = datetime.datetime.strptime(
        #             basicInfo["release"], "%Y-%m-%d").strftime("%Y")
        #         releaseDate = date.strftime("%Y")
        #     except:
        #         pass
        # logging.debug("releaseDate: {}".format(releaseDate))

        songInfo = self._songInfo(videoID)
        if preferSong:
            if songInfo:
                videoID = songInfo["videoDetails"]["videoId"]
            else:
                raise DownloadError("song not found {}".format(videoID))

        title = self.songTitle(videoID)
        logging.debug("title: {}".format(title))
        artists = self.songArtists(videoID)
        logging.debug("artists: {}".format(artists))
        albumArtist = self.songAlbumArtist(videoID)
        logging.debug("albumArtist: {}".format(albumArtist))
        album = self.songAlbum(videoID)
        logging.debug("album: {}".format(album))
        # track = self.songTrack(videoInfo)
        # releaseDate = self.songReleaseDate(videoInfo)
        # songURL = self.songURL(videoInfo)
        # artistUrl = self.songArtistURL(videoInfo)
        # albumArtURL = self.songAlbumArtURL(videoInfo)

        # tmpFileName = "{}.mp3".format(id)
        # logging.debug("tmpFileName: {}".format(tmpFileName))

        # tmpFilePath = "{}/{}".format(self.folder, tmpFileName)
        # logging.debug("tmpFilePath: {}".format(tmpFilePath))

        # fileName = title
        # if albumArtist:
        #     fileName = "{} - {}".format(albumArtist, title)
        # fileName = unicodedata.normalize("NFKD", fileName).encode(
        #     "ascii", "ignore").decode("ascii")
        # fileName = re.sub("[^\w\s\(\)\-]", " ", fileName)
        # fileName = re.sub("\s\s+", " ", fileName).strip()
        # fileName = "{}.mp3".format(fileName)
        # logging.debug("fileName: {}".format(fileName))

        # filePath = "{}/{}".format(self.folder, fileName)
        # logging.debug("filePath: {}".format(filePath))

        # logging.debug("finished gathering metadata")

        # if os.path.exists(filePath):
        #     if self.overwrite:
        #         logging.info("found existing song '{}' by '{}', overwriting".format(
        #             title, albumArtist))
        #     else:
        #         logging.info("found existing song '{}' by '{}', skipping".format(
        #             title, albumArtist))
        #         return

        # try:
        #     with youtube_dl.YoutubeDL({
        #         "format": "bestaudio/best",
        #         "postprocessors": [{
        #             "key": "FFmpegExtractAudio",
        #             "preferredcodec": "mp3",
        #             "preferredquality": "320",
        #         }],
        #         "outtmpl": tmpFilePath.replace(".mp3", ".%(ext)s"),
        #         "logger": logging
        #     }) as ydl:
        #         ydl.download([songURL])
        # except youtube_dl.utils.DownloadError:
        #     raise DownloadError("failed to download")
        # logging.debug("finished downloading")

        # tag = eyed3.id3.Tag(version=eyed3.id3.ID3_V2_3)
        # if title:
        #     tag.title = title
        # if artists:
        #     tag.artist = ";".join(artists)
        # if albumArtist:
        #     tag.album_artist = albumArtist
        # if album:
        #     tag.album = album
        # if track:
        #     tag.track_num = track
        # if releaseDate:
        #     tag.release_date = releaseDate
        #     tag.original_release_date = releaseDate
        #     tag.recording_date = releaseDate
        # if songURL:
        #     tag.audio_source_url = songURL
        #     tag.internet_radio_url = songURL
        # if artistUrl:
        #     tag.artist_url = artistUrl

        # if albumArtURL:
        #     logging.debug("downloading album art")
        #     art = Image.open(urlopen(albumArtURL))
        #     width, height = art.size
        #     if width > 544 and height > 544:
        #         if width > height:
        #             width = round(544.0 / height * width)
        #             height = 544
        #         elif width < height:
        #             height = round(544.0 / width * height)
        #             width = 544
        #     art = art.resize((width, height))
        #     rawArt = io.BytesIO()
        #     art.save(rawArt, format="jpeg")
        #     tag.images.set(eyed3.id3.frames.ImageFrame.FRONT_COVER,
        #                    rawArt.getvalue(), "image/jpeg")
        #     logging.debug("added album art")

        # tag.save(filename=tmpFilePath, version=eyed3.id3.ID3_V2_3)
        # logging.debug("finished tagging")

        # os.rename(tmpFilePath, filePath)

        # logging.info("finished downloading song '{}' by '{}'".format(
        #     title, albumArtist))

    def songTitle(self, videoID):
        videoInfo = self._videoInfo(videoID)
        return videoInfo["videoDetails"]["title"]

    def songArtists(self, videoID):
        artists = []
        artistIDs = []

        searchInfo = self._searchInfo(videoID)
        if searchInfo:
            for artist in searchInfo["artists"]:
                if artist["id"] not in artistIDs:
                    try:
                        artistInfo = self._artistInfo(artist["id"])
                    except:
                        name = artist["name"]
                    else:
                        name = artistInfo["name"]
                    if name not in artists:
                        artists.append(name)
                        artistIDs.append(artist["id"])
        else:
            videoInfo = self._videoInfo(videoID)
            artists = [videoInfo["videoDetails"]["author"]]

        return artists

    def songAlbumArtist(self, videoID):
        artists = self.songArtists(videoID)
        if len(artists) > 0:
            return artists[0]
        else:
            return None

    def songAlbum(self, videoID):
        albumInfo = self._albumInfo(videoID)
        searchInfo = self._searchInfo(videoID)
        if albumInfo:
            return albumInfo["title"]
        elif searchInfo:
            return searchInfo["album"]["name"]


def main():
    loggingLevel = logging.INFO

    args = getargs()
    if args.verbose:
        loggingLevel = logging.DEBUG

    logging.basicConfig(level=loggingLevel)

    downloader = Downloader(args)

    for url in args.url:
        parsedURL = urlparse(url)
        queryParams = parse_qs(parsedURL.query)
        if parsedURL.path.startswith("/channel"):
            downloader.channel(parsedURL.path.split("/")[2])
        elif parsedURL.path.startswith("/playlist"):
            downloader.playlist(queryParams["list"][0])
        elif parsedURL.path.startswith("/watch"):
            downloader.song(queryParams["v"][0])


if __name__ == "__main__":
    main()
