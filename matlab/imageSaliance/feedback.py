bufferpath = "../../dataAcq/buffer/python"

import sys, pygame, random, math, PIL
sys.path.append(bufferpath)
import FieldTrip

# Value definitions
hostname='localhost'
port=1972

targetPath = './pictures/targets'

width=800
height=600






# Buffer interfacing functions 
def sendEvent(event_type, event_value=1, offset=0):
    e = FieldTrip.Event()
    e.type = event_type
    e.value = event_value
    if offset > 0:
        sample, bla = ftc.poll() #TODO: replace this with a clock-sync based version
        e.sample = sample + offset + 1
    ftc.putEvents(e)

def buffer_newevents(timeout=3000):
    '''
    Wait for and return any new events recieved from the buffer between
    calls to this function
    
    timeout    = maximum time to wait in milliseconds before returning
    '''
    start, nEvents = ftc.poll()

    stop = False
    timetogo=timeout
    while not stop and timetogo>0:
        nSamples,curEvents=ftc.wait(-1,nEvents, timetogo)
        if curEvents>nEvents:
            return ftc.getEvents([nEvents,curEvents])
            nEvents = curEvents
    return events

#Connect to Buffer
timeout=5000
ftc = FieldTrip.Client()

# Wait until the buffer connects correctly and returns a valid header
hdr = None;
while hdr is None :
    print('Trying to connect to buffer on %s:%i ...'%(hostname,port))
    try:
        ftc.connect(hostname, port)
        print('\nConnected - trying to read header...')
        hdr = ftc.getHeader()
    except IOError:
        pass

    if hdr is None:
        print('Invalid Header... waiting')
        sleep(1)
    else:
        print(hdr)
        print(hdr.labels)
  
fSample = hdr.fSample






# Initialize pygame
pygame.init()
screen = pygame.display.set_mode((width,height),  1, 32)
pygame.display.set_caption("Image Salience -- Feedback")

clock = pygame.time.Clock()

# Initialize display state data
surfaces = {}
fragmentSampleMap = {}

# Function to slice image into fragments.
def sliceImage(img,columns,rows):
	slices = []
	(width,height) = im.size

	tile_w = width/columns
	tile_h = height/rows

	for y in rows:
		row = []
		for x in columns:
			area = (tile_w*x, tile_h*y, tile_w*x + tile_w, tile_h*y + tile_h)
			fragment = img.crop(area)
			row.append(fragment)
		slices.append(row)

	return slices

# Load image, create fragments, convert to surfaces and store.
def loadImage(name):
	image_path = os.path.join(targetPath, evt.value + ".jpg")
	img = PIL.Image.open(image_path)
	
	cols = 3;
	rows = 3;

	(img_width, img_height) = im.size
	if img_width > 1.5 * img_height:
		cols = 4

	slices = sliceImage(img, cols, rows)

	for y in range(0, rows):
		for x in range(0, cols):
			# save temp
			tempname = name + '.temp.png';
			im.save(tempname)

			# load into pygame surface
			surf = pygame.image.load(tempname)
			surf.set_alpha(255)

			# determine target blit area
			pos_x = 0 if x == 0 else width/cols  #pos_x = x == 0 ? 0 : width / cols
			pos_y = 0 if y == 0 else height/rows #pos_y = y == 0 ? 0 : width / rows
			w = pos_x + width/cols
			h = pos_y + height/rows
	
			# Store in dictionary
			frag_no = x * cols + y
			surfaces[frag_no] = (pygame.Rect(pos_x, pos_y, w,h), surf, []) # Store as (screen_dst, surface, [probabilities])
						
	





# Function convert prediction to probablity [0-1]
def predictionToProbablity(pred):
	return 1.0 / (1.0 + math.exp(pred))

# Scales alpha [0-1] to (possibly) more useful alpha values [0-1]
def scaleAlpha(alpha):
	return alpha #TODO: Determine if we want to change this.

# Receive events from the buffer and process them.
def processBufferEvents():
	events = buffer_newevents()

	for evt in events:
		if evt.type == 'stimulus.target.image': # Target image was received, load the image.
			surfaces = {} # Clear surfaces, i.e. reset.
			loadImage(evt.value)

		elif evt.type == 'stimulus.image': # Select the next fragment.
			fragment = int(evt.value.split('/')[1])
			sample = evt.sample
			fragmentSampleMap[sample] = fragment

		elif evt.type == 'classifier.prediction':
			# Get fragment from map and delete entry.
			sample = evt.sample
			fragment = fragmentSampleMap[sample]
			del fragmentSampleMap[sample]

			# Set alpha value.
			pred = evt.value
			prob = predictionToProbability(pred)
			surfaces[fragment][2].append(prob)
			alpha = 255 * scaleAlpha(sum(surfaces[fragment][2])/len(surfaces[fragment][2])) # compute alpha of average probability over time.
			surfaces[fragment][1].set_alpha(alpha)
	



# Event loop
done = False
while not done:
	for event in pygame.event.get():
		if event.type == pygame.QUIT:
			done=True

	# Fetch and process events.
	processBufferEvents()

	# Clear screen.
	screen.fill(black)

	# Display surfaces.
	for i in range(0, len(surface)):
		k = i+1
		dst = surfaces[key][0]
		img = surfaces[key][1]
		screen.blit(img, dst)

	# Flip buffers.
	pygame.display.flip()

# Deinitialize
pygame.quit()
