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
        self.ytm = ytmusicapi.YTMusic()

        self.songInfo = {}
        self.artistInfo = {}
        self.albumInfo = {}

    def _songInfo(self, id):
        if id in self.songInfo:
            return self.songInfo[id]

        songInfo = self.ytm.get_song(id)
        self.songInfo[id] = songInfo
        return songInfo

    def _artistInfo(self, id):
        if id in self.artistInfo:
            return self.artistInfo[id]

        artistInfo = self.ytm.get_artist(id)
        self.artistInfo[id] = artistInfo
        return artistInfo

    def _albumInfo(self, id):
        if id in self.albumInfo:
            return self.albumInfo[id]

        try:
            albumInfo = self.ytm.get_album(id)
        except:
            albumInfo = None

        self.albumInfo[id] = albumInfo
        return albumInfo

    def channel(self, id):
        songs = []

        try:
            channelInfo = self._artistInfo(id)
        except KeyError as error:
            try:
                self.album(id)
                return
            except:
                raise error
        logging.debug("finished feching artist info")

        if "songs" in channelInfo and channelInfo["songs"]:
            songsList = channelInfo["songs"]["results"]
            if "browseId" in channelInfo["songs"] and channelInfo["songs"]["browseId"]:
                songsInfo = self.ytm.get_playlist(
                    channelInfo["songs"]["browseId"], 10000)
                songsList = songsInfo["tracks"]
            for song in songsList:
                songs.append(song["videoId"])
        logging.debug("finished feching artist songs")

        if "albums" in channelInfo and channelInfo["albums"]:
            albumsList = channelInfo["albums"]["results"]
            if "browseId" in channelInfo["albums"] and channelInfo["albums"]["browseId"]:
                albumsInfo = self.ytm.get_artist_albums(channelInfo["albums"]["browseId"],
                                                        channelInfo["albums"]["params"])
                albumsList = albumsInfo
            for album in albumsList:
                albumInfo = self._albumInfo(album["browseId"])
                if not albumInfo:
                    break
                for song in albumInfo["tracks"]:
                    songs.append(song["videoId"])
        logging.debug("finished feching artist albums")

        if "singles" in channelInfo and channelInfo["singles"]:
            singlesList = channelInfo["singles"]["results"]
            if "browseId" in channelInfo["singles"] and channelInfo["singles"]["browseId"]:
                singlesInfo = self.ytm.get_artist_albums(channelInfo["singles"]["browseId"],
                                                         channelInfo["singles"]["params"])
                singlesList = singlesInfo
            for single in singlesList:
                singleInfo = self._albumInfo(single["browseId"])
                if not singleInfo:
                    break
                for song in singleInfo["tracks"]:
                    songs.append(song["videoId"])
        logging.debug("finished feching artist singles")

        logging.info("finished fetching songs")
        self.songs(songs)

    def album(self, id):
        songs = []

        albumInfo = self._albumInfo(id)
        for song in albumInfo["tracks"]:
            songs.append(song["videoId"])

        logging.info("finished fetching songs")
        self.songs(songs)

    def playlist(self, id):
        songs = []

        with youtube_dl.YoutubeDL({
            "extract_flat": True,
            "quiet": True,
        }) as ydl:
            playlist = ydl.extract_info(
                "https://music.youtube.com/playlist?list={}".format(id), download=False)
            for song in playlist["entries"]:
                songs.append(song["id"])

        logging.info("finished fetching songs")
        self.songs(songs)

    def songs(self, songs):
        songsCopy = songs
        songs = []
        for song in songsCopy:
            if song not in songs:
                songs.append(song)

        logging.debug("downloading song list: {}".format(songs))

        for index in range(len(songs)):
            logging.info("downloading song {} of {}".format(
                index + 1, len(songs)))
            try:
                self.song(songs[index], True)
            except DownloadError as error:
                logging.warning("download failed: {}".format(error))

    def song(self, id, preferSong=False):
        logging.info("downlowding song: {}".format(id))

        basicInfo = self._songInfo(id)
        if "videoId" in basicInfo:
            id = basicInfo["videoId"]
        else:
            raise DownloadError("video not found {}".format(id))
        logging.debug("basicInfo: {}".format(basicInfo))

        searchQuery = basicInfo["title"]
        if "artists" in basicInfo:
            searchQuery += " " + " ".join(basicInfo["artists"])
        logging.debug("searchQuery: {}".format(searchQuery))

        searchInfo = None
        searchResults = self.ytm.search(searchQuery, filter="songs", limit=20)
        if len(searchResults) == 0:
            if preferSong:
                raise DownloadError("song not found {}".format(searchQuery))
        else:
            for result in searchResults:
                if result["videoId"] == id:
                    searchInfo = result
                    break
            else:
                searchInfo = searchResults[0]
        logging.debug("searchInfo: {}".format(searchInfo))

        songInfo = basicInfo
        if searchInfo and searchInfo["videoId"] != songInfo["videoId"]:
            songInfo = self._songInfo(searchInfo["videoId"])
        logging.debug("songInfo: {}".format(songInfo))

        albumInfo = None
        albumSongInfo = None
        if searchInfo and "album" in searchInfo and searchInfo["album"]:
            albumInfo = self._albumInfo(searchInfo["album"]["id"])
            if albumInfo and "tracks" in albumInfo and albumInfo["tracks"]:
                for albumSong in albumInfo["tracks"]:
                    if albumSong["title"] == searchInfo["title"]:
                        albumSongInfo = albumSong
                        break
        logging.debug("albumInfo: {}".format(albumInfo))
        logging.debug("albumSongInfo: {}".format(albumSongInfo))

        songUrl = "https://music.youtube.com/watch?v={}"
        if preferSong and songInfo:
            songUrl = songUrl.format(searchInfo["videoId"])
        else:
            songUrl = songUrl.format(id)
        logging.debug("songUrl: {}".format(songUrl))

        title = id
        if songInfo and "title" in songInfo:
            title = songInfo["title"]
        elif title in basicInfo:
            title = basicInfo["title"]
        logging.debug("title: {}".format(title))

        artists = []
        artistIds = []
        if searchInfo and "artists" in searchInfo and searchInfo["artists"]:
            for artist in searchInfo["artists"]:
                if artist["id"] not in artistIds:
                    try:
                        artistInfo = self._artistInfo(artist["id"])
                    except:
                        name = artist["name"]
                    else:
                        name = artistInfo["name"]
                    if name not in artists:
                        artists.append(name)
                        artistIds.append(artist["id"])
            if "artists" in songInfo and songInfo["artists"]:
                for artist in songInfo["artists"]:
                    if artist not in artists:
                        artists.append(artist)
        elif "artists" in basicInfo and basicInfo["artists"] and len(basicInfo["artists"]) > 0:
            artists = basicInfo["artists"]
        elif "author" in basicInfo:
            artists = [basicInfo["author"]]
        logging.debug("artists: {}".format(artists))

        albumArtist = None
        if len(artists) > 0:
            albumArtist = artists[0]
        logging.debug("albumArtist: {}".format(albumArtist))

        artistUrl = None
        if len(artistIds) > 0:
            artistUrl = "https://music.youtube.com/channel/{}".format(
                artistIds[0])
        elif "channelId" in basicInfo:
            artistUrl = "https://music.youtube.com/channel/{}".format(
                basicInfo["channelId"])
        logging.debug("artistUrl: {}".format(artistUrl))

        album = None
        if albumInfo and "title" in albumInfo:
            album = albumInfo["title"]
        elif searchInfo and "album" in searchInfo and searchInfo["album"]:
            album = searchInfo["album"]["name"]
        logging.debug("album: {}".format(album))

        albumArt = None
        if albumInfo and "thumbnails" in albumInfo and albumInfo["thumbnails"] and len(albumInfo["thumbnails"]) > 0:
            albumInfo["thumbnails"].sort(
                key=lambda art: art["width"], reverse=True)
            albumArt = albumInfo["thumbnails"][0]["url"]
        elif "thumbnail" in basicInfo and basicInfo["thumbnail"] and "thumbnails" in basicInfo["thumbnail"] and basicInfo["thumbnail"]["thumbnails"] and len(basicInfo["thumbnail"]["thumbnails"]) > 0:
            basicInfo["thumbnail"]["thumbnails"].sort(
                key=lambda art: art["width"], reverse=True)
            albumArt = basicInfo["thumbnail"]["thumbnails"][0]["url"]
        logging.debug("albumArt: {}".format(albumArt))

        trackNum = None
        if albumSongInfo and "index" in albumSongInfo:
            trackNum = albumSongInfo["index"]
        tracksNum = None
        if albumInfo and "trackCount" in albumInfo:
            tracksNum = albumInfo["trackCount"]
        track = (trackNum, tracksNum)
        logging.debug("trackNum: {}".format(trackNum))

        releaseDate = None
        if albumInfo and "releaseDate" in albumInfo and albumInfo["releaseDate"]:
            releaseDate = "{}".format(albumInfo["releaseDate"]["year"])
        elif songInfo and "release" in songInfo:
            try:
                date = datetime.datetime.strptime(
                    songInfo["release"], "%Y-%m-%d")
                releaseDate = date.strftime("%Y")
            except:
                pass
        elif "release" in basicInfo:
            try:
                date = datetime.datetime.strptime(
                    basicInfo["release"], "%Y-%m-%d").strftime("%Y")
                releaseDate = date.strftime("%Y")
            except:
                pass
        logging.debug("releaseDate: {}".format(releaseDate))

        tmpFileName = "{}.mp3".format(id)
        logging.debug("tmpFileName: {}".format(tmpFileName))

        tmpFilePath = "{}/{}".format(self.folder, tmpFileName)
        logging.debug("tmpFilePath: {}".format(tmpFilePath))

        fileName = "{}.mp3".format(title.replace("/", ","))
        if albumArtist:
            fileName = "{} - {}".format(albumArtist.replace("/",
                                                            ","), fileName)
        fileName.strip()
        logging.debug("fileName: {}".format(fileName))

        filePath = "{}/{}".format(self.folder, fileName)
        logging.debug("filePath: {}".format(filePath))

        logging.debug("finished gathering metadata")

        if os.path.exists(filePath):
            if self.overwrite:
                logging.info("found existing song '{}' by '{}', overwriting".format(
                    title, albumArtist))
            else:
                logging.info("found existing song '{}' by '{}', skipping".format(
                    title, albumArtist))
                return

        try:
            with youtube_dl.YoutubeDL({
                "format": "bestaudio/best",
                "postprocessors": [{
                    "key": "FFmpegExtractAudio",
                    "preferredcodec": "mp3",
                    "preferredquality": "320",
                }],
                "outtmpl": tmpFilePath.replace(".mp3", ".%(ext)s"),
                "logger": logging
            }) as ydl:
                ydl.download([songUrl])
        except youtube_dl.utils.DownloadError:
            raise DownloadError("failed to download")
        logging.debug("finished downloading")

        tag = eyed3.id3.Tag(version=eyed3.id3.ID3_V2_3)
        if title:
            tag.title = title
        if artists:
            tag.artist = ";".join(artists)
        if albumArtist:
            tag.album_artist = albumArtist
        if album:
            tag.album = album
        if track:
            tag.track_num = track
        if releaseDate:
            tag.release_date = releaseDate
            tag.original_release_date = releaseDate
            tag.recording_date = releaseDate
        if songUrl:
            tag.audio_source_url = songUrl
            tag.internet_radio_url = songUrl
        if artistUrl:
            tag.artist_url = artistUrl

        if albumArt:
            logging.debug("downloading album art")
            art = Image.open(urlopen(albumArt))
            width, height = art.size
            if width > 544 and height > 544:
                if width > height:
                    width = round(544.0 / height * width)
                    height = 544
                elif width < height:
                    height = round(544.0 / width * height)
                    width = 544
            art = art.resize((width, height))
            rawArt = io.BytesIO()
            art.save(rawArt, format="jpeg")
            tag.images.set(eyed3.id3.frames.ImageFrame.FRONT_COVER,
                           rawArt.getvalue(), "image/jpeg")
            logging.debug("added album art")

        tag.save(filename=tmpFilePath, version=eyed3.id3.ID3_V2_3)
        logging.debug("finished tagging")

        os.rename(tmpFilePath, filePath)

        logging.info("finished downloading song '{}' by '{}'".format(
            title, albumArtist))


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
