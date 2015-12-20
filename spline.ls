spline = do
  update: (points, lines) ->
    # TODO : get x and y for every point

    /*computes control points p1 and p2 for x and y direction*/
    px = @computeControlPoints x = [p.x for p in points]
    py = @computeControlPoints y = [p.y for p in points]

    /*updates path settings, the browser will draw the new spline*/
    for i from 0 til lines.length =>
      lines[i].d = @path x[i], y[i], px.p1[i], py.p1[i], px.p2[i], py.p2[i], x[i+1], y[i+1]

  path: (x1, y1, px1, py1, px2, py2, x2, y2) -> "M #x1 #y1 C #px1 #py1 #px2 #py2 #x2 #y2"
  
  # heteroformat ( {anchor, ctrl1, ctrl2})
  add-ctrls: (pts) ->
    px = @computeControlPoints x = [(p.x or p.0 or p.[]anchor.0) for p in pts]
    py = @computeControlPoints y = [(p.y or p.1 or p.[]anchor.1) for p in pts]
    for i from 0 til pts.length =>
      pts[i].anchor = [x[i], y[i]]
      if i > 0 => pts[i].ctrl1  = [px.p2[i - 1], py.p2[i - 1]]
      else pts[i].ctrl1 = [x[i],y[i]]
      if i < pts.length - 1 => pts[i].ctrl2  = [px.p1[i], py.p1[i]]
      else pts[i].ctrl2 = [x[i],y[i]]
    pts

  computeControlPoints: (K) ->
    [p1,p2] = [[],[]]
    [a,b,c,r,n] = [[0],[2],[1],[K.0 + 2 * K.1], K.length - 1]
    for i from 1 til n - 1
      a.push 1
      b.push 4
      c.push 1
      r.push 4 * K[i] + 2 * K[i + 1]
    a.push 2
    b.push 7
    c.push 0
    r.push 8 * K[n-1] + K[n]

    for i from 1 til n
      m = a[i] / b[i - 1]
      b[i] = b[i] - m * c[i - 1]
      r[i] = r[i] - m * r[i - 1]

    p1[n - 1] = r[n - 1] / b[n - 1]
    for i from n - 2 to 0 by -1
      p1[i] = (r[i] - c[i] * p1[i + 1]) / b[i]

    for i from 0 til n - 1
      p2[i] = 2 * K[i + 1] - p1[i + 1]
    p2[n - 1] = (K[n] + p1[n - 1])/2

    return {p1, p2}
