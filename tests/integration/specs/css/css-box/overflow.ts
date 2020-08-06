describe('Overflow', () => {
  it('basic', async () => {
    var container = document.createElement('div');
    var div1 = document.createElement('div');
    Object.assign(div1.style, {
      overflowX: 'scroll',
      overflowY: 'visible',
      width: '100px',
      height: '100px',
    });

    var inner1 = document.createElement('div');
    Object.assign(inner1.style, {
      width: '120px',
      height: '120px',
      backgroundColor: 'red',
    });
    div1.appendChild(inner1);
    container.appendChild(div1);

    var div2 = document.createElement('div');
    Object.assign(div2.style, {
      overflowX: 'visible',
      overflowY: 'hidden',
      width: '100px',
      marginTop: '40px',
      height: '100px',
    });
    var inner2 = document.createElement('div');
    Object.assign(inner2.style, {
      width: '120px',
      height: '120px',
      backgroundColor: 'red',
    });
    div2.appendChild(inner2);
    container.appendChild(div2);

    var div3 = document.createElement('div');
    Object.assign(div3.style, {
      overflowX: 'hidden',
      overflowY: 'scroll',
      width: '100px',
      marginTop: '40px',
      height: '100px',
    });
    var inner3 = document.createElement('div');
    Object.assign(inner3.style, {
      width: '120px',
      height: '120px',
      backgroundColor: 'red',
    });
    div3.appendChild(inner3);
    container.appendChild(div3);

    document.body.appendChild(container);

    await matchViewportSnapshot();
  });

  it('scrollTo', async (done) => {
    let container = document.createElement('div');
    let div1 = document.createElement('div');
    Object.assign(div1.style, {
      overflowX: 'scroll',
      overflowY: 'visible',
      width: '100px',
      height: '100px',
    });

    let inner1 = document.createElement('div');
    Object.assign(inner1.style, {
      width: '120px',
      height: '120px',
      background: 'conic-gradient(from -90deg, blue 0 25%, black 25% 50%, red 50% 75%, green 75% 100%)',
    });

    div1.appendChild(inner1);
    container.appendChild(div1);

    requestAnimationFrame(async () => {
      div1.scroll(20, 20);
      await matchViewportSnapshot();
      done();
    });
    document.body.appendChild(container);
  });

  it('overflow with inner padding', async () => {
    let div;
    div = createElement(
      'div',
      {
        style: {
          width: '150px',
          height: '150px',
          border: '10px solid #f40',
          padding: '10px',
          overflow: 'auto',
          background: 'conic-gradient(from -90deg, blue 0 25%, black 25% 50%, red 50% 75%, green 75% 100%)',
        },
      }, [
        createText('London. Michaelmas term lately over, and the Lord Chancellor sitting in Lincolns Inn Hall. Implacable November weather. As much mud in the streets as if the waters had but newly retired from the face of the earth, and it would not be wonderful to meet a Megalosaurus, forty feet long or so, waddling like an elephantine lizard up Holborn Hill.')
      ],
    );
    BODY.appendChild(div);
    await matchViewportSnapshot(0.2);
  });
});
