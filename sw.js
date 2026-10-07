/* 読書記録アプリのオフライン対応。
   ねらいは「機内モード・地下鉄でもアプリが開いて、読んだ記録を書けること」。
   書いた内容は端末(localStorage)に保存され、オンラインに戻るとアプリ側が
   自動でクラウドへ送る(index.html の handlePendingCloud / flushPendingCloud)。

   アプリ本体(index.html)は毎回まずネットから取りに行き、取れないときだけ
   控えを使う(network-first)。以前PWAで「古い版がキャッシュに残り続けて
   更新が届かない」事故があったため、本体は必ず新しい方を優先する。
   アイコンなど変わらないものは控えを先に使う(cache-first)。 */
const CACHE_NAME = 'reading-log-v8';
const FONT_CACHE = 'reading-log-fonts';   // 書体は版を上げても消さない
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './kanji-yomi.js',   // フレーズ検索の漢字の読み(変わらないので控えを使う)
  './icons/icon-192.png?v=4',
  './icons/icon-512.png?v=4',
  './icons/apple-touch-icon.png?v=4',
  './icons/favicon-32.png?v=4',
].map(p => new URL(p, self.registration.scope).toString());

const INDEX_URL = new URL('./index.html', self.registration.scope).toString();

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      // 1つでも取れないと全部失敗するので、1件ずつ入れて失敗は見逃す
      .then(cache => Promise.all(APP_SHELL.map(url => cache.add(url).catch(() => null))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE_NAME && k !== FONT_CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const req = event.request;
  if(req.method !== 'GET') return;

  const url = new URL(req.url);
  // 見出しの明朝(Google Fonts)だけは別のサイトでも控えを持つ。
  // 一度読めば、機内モードでも同じ書体で開ける(控えが無ければ端末の明朝になる)
  if(url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com'){
    event.respondWith(
      caches.open(FONT_CACHE).then(cache => cache.match(req).then(hit => {
        const net = fetch(req).then(res => {
          if(res && (res.ok || res.type === 'opaque')) cache.put(req, res.clone());
          return res;
        }).catch(() => hit);
        return hit || net;
      }))
    );
    return;
  }
  // 別のサイト(Firebase・書誌検索・表紙画像など)には手を出さない。
  // オフラインのときは普通に失敗させ、アプリ側のオフライン処理に任せる。
  if(url.origin !== self.location.origin) return;

  // 画面遷移とアプリ本体は「まずネット、だめなら控え」
  if(req.mode === 'navigate' || url.pathname.endsWith('/') || url.pathname.endsWith('index.html')){
    event.respondWith(
      fetch(req)
        .then(res => {
          if(res && res.ok){
            const copy = res.clone();
            caches.open(CACHE_NAME).then(cache => cache.put(INDEX_URL, copy));
          }
          return res;
        })
        .catch(() => caches.match(INDEX_URL).then(hit => hit || caches.match(req)))
    );
    return;
  }

  // それ以外(アイコンなど)は「まず控え、無ければネット」
  event.respondWith(
    caches.match(req).then(hit => hit || fetch(req).then(res => {
      if(res && res.ok){
        const copy = res.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(req, copy));
      }
      return res;
    }))
  );
});
