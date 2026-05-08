class ServerConstants {
  static List<String> getTvServers(int id, int season, int episode) {
    return [
      'https://vidfast.pro/tv/$id/$season/$episode?autoPlay=true',
      'https://moviesapi.club/tv/$id-$season-$episode',
      'https://multiembed.mov/?video_id=$id&tmdb=1&s=$season&e=$episode',
      'https://vidsrc.me/embed/tv?tmdb=$id&season=$season&episode=$episode',
    ];
  }

  static List<String> getMovieServers(int id) {
    return [
      'https://vidfast.pro/movie/$id?autoPlay=true',
      'https://moviesapi.club/movie/$id',
      'https://multiembed.mov/?video_id=$id&tmdb=1',
      'https://vidsrc.me/embed/movie?tmdb=$id',
    ];
  }
}
