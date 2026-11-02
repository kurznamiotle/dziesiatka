// Loads the app only after the click, so visitors who just read the page don't
// download it or contact any other server. Without a mouse the link opens the
// app on the full screen, because a frame would catch every scroll.
const start = document.querySelector('#demo-start');
const stage = document.querySelector('#demo-stage');
const fullScreenLink = document.querySelector('#demo-full');
const fitsBesideText = window.matchMedia(
  '(min-width: 861px) and (pointer: fine)',
);

start.addEventListener('click', (event) => {
  if (!fitsBesideText.matches) return;

  event.preventDefault();
  let frame = stage.querySelector('iframe');
  if (!frame) {
    frame = document.createElement('iframe');
    frame.className = 'demo-frame';
    frame.title = 'Dziesiątka, wersja demonstracyjna';
    frame.src = start.getAttribute('href');
    stage.querySelector('.deck').replaceWith(frame);
    fullScreenLink.hidden = false;
  }
  frame.focus();
  // A laptop's window is often shorter than the hero with the frame in it.
  stage.scrollIntoView({ block: 'center' });
});
