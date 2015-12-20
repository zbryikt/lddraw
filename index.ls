<- $ document .ready
doc = document
svg = 'http://www.w3.org/2000/svg'
Node.prototype.attr = -> 
  if typeof(it) == typeof("") => return @getAttribute it
  [[k,v] for k,v of it].map ([k,v]) ~> @setAttribute k,v
  @

node = doc.getElementById(\svg)

Path = (root) ->
  if !root => 
    @root = root = doc.createElementNS(svg, 'svg')
    root.attr do
      width: \400px
      height: \400px
      viewport: "0 0 400 400"
      preserveAspectRatio: "xMidYMid"
      class: "lddraw simple"
  root.owner = @
  b = root.getBoundingClientRect!
  @ <<< do
    box: [ [b.width * 0.2, b.height * 0.2], [b.width * 0.8, b.height * 0.8] ]
    pts: []
    dom: {pts: [], ctrl1: {line: [], pts: []}, ctrl2: {line: [], pts: []}}

  # path
  @dom.path = doc.createElementNS(svg, \path)
    ..attr class: \pts-path
  root.appendChild @dom.path

  # resizing box rectangle
  @dom.box = doc.createElementNS(svg,\rect)
  @dom.box.attr class: \box
  root.appendChild @dom.box

  # resizing box pointers
  @dom.boxptr = [doc.createElementNS(svg, \circle) for i from 0 til 4]
  @dom.boxptr.map (n,i) ~> 
    [x,y] = [@box[i % 2].0, @box[+(i > 1)].1]
    n.attr r: 4, class: \box-ptr
    n <<< owner: @, type: Path.BOXPTR, idx: i
    root.appendChild n

  # randomize points for testing
  step = 0.6
  if false => @pts = for r from 0 til 6.28 by step =>
    x = 200 + 100 * Math.cos(r)
    y = 200 + 100 * Math.sin(r)
    cx1 = 200 + 100 * Math.cos(r - step/3) - x
    cy1 = 200 + 100 * Math.sin(r - step/3) - y
    cx2 = 200 + 100 * Math.cos(r + step/3) - x
    cy2 = 200 + 100 * Math.sin(r + step/3) - y
    {ctrl1: [cx1,cy1], ctrl2: [cx2,cy2], anchor: [x,y]}
  @update!
  #stroke writing animation
  @curpercent = 0
  setInterval (~>
    return
    if !@dom.path => return
    if @curpercent < 1 =>
      curlen = @pathlen * @curpercent
      @dom.path.attr "stroke-dasharray": "#{curlen} #{@pathlen - curlen}"
    else
      curlen = @pathlen * ( @curpercent - 1 )
      @dom.path.attr "stroke-dasharray": "0 #{curlen} #{@pathlen - curlen}"
    @curpercent += 0.05
    if @curpercent >= 2 => @curpercent = 0
  ),100

  root.addEventListener \mousedown, @mouse.down
  root.addEventListener \mousemove, @mouse.move
  root.addEventListener \mouseup, @mouse.up
  @

Path.prototype <<< do
  resize-box: (des = @box) ->
    if @pts.length =>
      des.0.0 = des.1.0 = @pts.0.anchor.0
      des.0.1 = des.1.1 = @pts.0.anchor.1
    for pts in @pts =>
      if pts.anchor.0 > des.1.0 => des.1.0 = pts.anchor.0
      if pts.anchor.0 < des.0.0 => des.0.0 = pts.anchor.0
      if pts.anchor.1 > des.1.1 => des.1.1 = pts.anchor.1
      if pts.anchor.1 < des.0.1 => des.0.1 = pts.anchor.1

  resize-pts: ->
    box = [[0,0],[0,0]]
    @resize-box box
    rx = ( @box.1.0 - @box.0.0 ) / ( box.1.0 - box.0.0 )
    ry = ( @box.1.1 - @box.0.1 ) / ( box.1.1 - box.0.1 )
    for pts in @pts =>
      pts.ctrl1.0 *= rx
      pts.ctrl1.1 *= ry
      pts.ctrl2.0 *= rx
      pts.ctrl2.1 *= ry
      pts.anchor.0 = ( pts.anchor.0 - box.0.0 ) * rx + @box.0.0
      pts.anchor.1 = ( pts.anchor.1 - box.0.1 ) * ry + @box.0.1
    
  reset: ->
    @pts = []
    @resize-box!
    @update!

  update: ->
    if @dom.pts.length - @pts.length =>
      if that > 0 => 
        for i from @dom.pts.length til @pts.length by -1 =>
          @root.removeChild @dom.pts.pop!
          @root.removeChild @dom.ctrl1.line.pop!
          @root.removeChild @dom.ctrl1.pts.pop!
          @root.removeChild @dom.ctrl2.line.pop!
          @root.removeChild @dom.ctrl2.pts.pop!
      else
        for i from @dom.pts.length til @pts.length =>
          for c in <[ctrl1 ctrl2]> =>

            n = doc.createElementNS(svg, \line)
            n.attr do
              x1: @pts[i].anchor.0
              y1: @pts[i].anchor.1
              x2: @pts[i].anchor.0 + @pts[i][c]0
              y2: @pts[i].anchor.1 + @pts[i][c]1
              class: \pts-ctrl-line
            @dom[c].line.push n
            @root.appendChild n

            n = doc.createElementNS(svg, \circle)
            n.attr do
              cx: @pts[i].anchor.0 + @pts[i][c]0
              cy: @pts[i].anchor.1 + @pts[i][c]1
              r: 3
              class: \pts-ctrl-ptr
            n <<< owner: @, type: Path.CTRL, idx: i, ctrl: c
            @dom[c].pts.push n
            @root.appendChild n

          n = doc.createElementNS(svg, \circle)
          n.attr do
            cx: @pts[i].anchor.0
            cy: @pts[i].anchor.1
            r:  5
            class: \pts-ptr
          n <<< owner: @, type: Path.POINT, idx: i
          @dom.pts.push n
          @root.appendChild n

    @dom.pts.map (n,i) ~>
      [x,y] = @pts[i].anchor
      n.attr cx: x, cy: y
      n.style.fill = if n.active => \#f00 else \#fff
      n.idx = i
    for c in <[ctrl1 ctrl2]> =>
      @dom[c]pts.map (n,i) ~>
        [x,y] = @pts[i].anchor
        [dx,dy] = @pts[i][c]
        n.attr cx: x + dx, cy: y + dy
      @dom[c]line.map (n,i) ~>
        [x,y] = @pts[i]anchor
        [dx,dy] = @pts[i][c]
        n.attr x1: x, y1: y, x2: x + dx, y2: y + dy

    @dom.box.attr do
      x: @box.0.0
      y: @box.0.1
      width: @box.1.0 - @box.0.0
      height: @box.1.1 - @box.0.1
    @dom.boxptr.map (n,i) ~> 
      [x,y] = [@box[i % 2].0, @box[+(i > 1)].1]
      n.attr cx: x, cy: y

    @dom.path.attr d: Path.from-points @pts
    @pathlen = @dom.path.get-total-length!

  mouse: do
    target: null
    down: (e) -> 
      @target = e.target
      @{sx, sy} = {sx: e.clientX, sy: e.clientY}
    move: (e) -> 
      if !e.buttons => return @target = null
      {cx, cy} = {cx: e.clientX, cy: e.clientY}
      if @target => 
        {owner,type,idx} = @target{owner,type,idx}
        if !owner => return
        b = owner.root.getBoundingClientRect!
        [cx,cy] = [cx - b.left, cy - b.top]
        if type == Path.BOXPTR =>
          b = owner.box
          [x,y] = [idx % 2, +(idx > 1)]
          if (!x and b.1.0 > cx) or (x and b.0.0 < cx) => b[x]0 = cx else b[x]0 = b[+!x]0 + 2 * x - 1
          if (!y and b.1.1 > cy) or (y and b.0.1 < cy) => b[y]1 = cy else b[y]1 = b[+!y]1 + 2 * y - 1
          owner.resize-pts!
          owner.update!
        else if type == Path.POINT =>
          [p,b] = [owner.pts, owner.box]
          p[idx].anchor.0 = cx
          p[idx].anchor.1 = cy
          owner.resize-box!
          owner.update!
        else if type == Path.CTRL =>
          a = owner.pts[idx].anchor
          ctrl = owner.pts[idx][@target.ctrl]
          ctrl.0 = cx - a.0
          ctrl.1 = cy - a.1
          owner.update!
        else if @target.nodeName.toLowerCase! == \svg => 
          if owner.pts.length > 0 => last = owner.pts[* - 1].anchor
          if owner.pts.length == 0 or (cx - last.0) ** 2 + (cy - last.1) ** 2 > 300 =>
            owner.pts.push {ctrl1: [0,0], ctrl2: [0,0], anchor: [cx,cy]}
            owner.resize-box!
            owner.update!
    up: ->
      if @target and @target.owner and @target.type == Path.POINT => 
        if @target.owner.active => that.active = false
        @target.active = true
        @target.owner.active = @target
        @target.owner.update!
      if @target and @target.owner and @target.nodeName.toLowerCase! == \svg =>
        pts = @target.owner.pts
        spline.add-ctrls pts
        for p in pts => 
          p.ctrl1.0 -= p.anchor.0
          p.ctrl1.1 -= p.anchor.1
          p.ctrl2.0 -= p.anchor.0
          p.ctrl2.1 -= p.anchor.1
        @target.owner.update!
      @target = null


Path <<< do
  POINT: 1
  CTRL: 2
  BOXPTR: 3
  from-points: (points, is-closed = false) ->
    if !points or !points.length => return ""
    ret = "M#{points.0.anchor.0} #{points.0.anchor.1}"
    last = points.0
    if is-closed => points = points ++ [points.0]
    for i from 1 til points.length =>
      item = points[i]
      c1x = last.anchor.0 + last.ctrl2.0
      c1y = last.anchor.1 + last.ctrl2.1
      c2x = item.anchor.0 + item.ctrl1.0
      c2y = item.anchor.1 + item.ctrl1.1
      ret += "C#{c1x} #{c1y} #{c2x} #{c2y} #{item.anchor.0} #{item.anchor.1}"
      last = item
    return ret

path = new Path!
$(\#root).0.appendChild path.root
