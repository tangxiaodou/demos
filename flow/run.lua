#!/usr/bin/env qlua
------------------------------------------------------------
-- a simple optical flow demo
--

require 'xlua'
require 'torch'
require 'qt'
require 'qtwidget'
require 'qtuiloader'
xrequire('camera',true)
require 'opencv'

-- parse args
op = xlua.OptionParser('%prog [options]')
op:option{'-c', '--camera', action='store', dest='camidx',
          help='if source=camera, you can specify the camera index: /dev/videoIDX', 
          default=0}
opt,args = op:parse()

-- setup GUI (external UI file)
widget = qtuiloader.load('g.ui')
win = qt.QtLuaPainter(widget.frame)

-- setup camera
camera = image.Camera(opt.camidx)
img1=torch.Tensor(3,480,640)
img2=torch.Tensor(3,480,640)

-- process function
function process()
   -- flow - from testme function:
   -- grab frames
   img1 = img1:copy(camera:forward())
   img2 = img2:copy(camera:forward())
   local norm, angle, flow_x, flow_y = opencv.CalcOpticalFlow{pair={img1,img2}, method='LK'}
   
   local hsl = torch.Tensor(3,img1:size(2), img1:size(3))
   hsl:select(1,1):copy(angle):div(360)
   hsl:select(1,2):copy(norm):div(math.max(norm:max(),1e-2))
   hsl:select(1,3):fill(0.5)
   local rgb = image.hsl2rgb(hsl) 
   frame=rgb  
end   
      
--   local methods = {'LK', 'HS', 'BM'}
--   for i,method in ipairs(methods) do
--      print(i,method)
--      local norm, angle, flow_x, flow_y =
--	 opencv.CalcOpticalFlow{pair={img1,img2}, method=method}
--      local hsl = torch.Tensor(3,img1:size(2), img1:size(3))
--      hsl:select(1,1):copy(angle):div(360)
--      hsl:select(1,2):copy(norm):div(math.max(norm:max(),1e-2))
--      hsl:select(1,3):fill(0.5)
--      local rgb = image.hsl2rgb(hsl)
--      image.display{image={img1,img2,rgb},
--		    legend='cvOpticalFLow, method = ' .. method,
--		    legends={'input 1', 'input2', 'HSL-mapped flow'}}
--      image.display{image={norm,angle,flow_x,flow_y},
--                    scaleeach=true,
--		    legend='cvOpticalFLow, method = ' .. method,
--		    legends={'norm','angle', 'flow x', 'flow y'}}
--

-- display function
function display()
   zoom = 1
   win:gbegin()
   win:showpage()
   image.display{image=frame, win=win, zoom=zoom}
   win:gend()
end

-- setup gui
local timer = qt.QTimer()
timer.interval = 10
timer.singleShot = true
qt.connect(timer,
           'timeout()',
           function()
              process()
              display()
              timer:start()
           end)

-- calls back for all buttons

widget.windowTitle = 'Optical Flow live'
widget:show()
timer:start()
