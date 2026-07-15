# Web deployment

After every `flutter build web`, copy `web/_redirects` into `build/web/`
before uploading the artifact. Flutter does not copy dot/underscore host
configuration files automatically. CI performs this step explicitly.

The Flutter web app uses GoRouter paths such as `/dictionary`, `/path`, and
`/profile`. Configure the host to return `index.html` with HTTP 200 for every
unknown application path; otherwise a direct link or a page refresh returns
404 before Flutter starts.

## Netlify

`web/_redirects` is copied into `build/web/` by `flutter build web` and
contains the required fallback:

```text
/*    /index.html   200
```

Publish `nokhchiin/build/web`.

## Other hosts

- Firebase Hosting: use a rewrite from `**` to `/index.html`.
- Vercel: rewrite every non-file route to `/index.html`.
- Nginx: use `try_files $uri $uri/ /index.html;`.

Before publishing, verify a fresh browser session can open `/dictionary` and
`/profile` directly, not only after navigating from the home screen.
