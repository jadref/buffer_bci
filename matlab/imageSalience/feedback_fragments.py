bufferpath = "../../dataAcq/buffer/python"

import os, sys, pygame, random, math, time
sys.path.append(os.path.dirname(__file__)+bufferpath)
import FieldTrip
from PIL import Image

# Value definitions
image_paths = ['./pictures/targets', './pictures/distractors', './pictures/test', './pictures/training']

hostname='localhost'
port=1972

width=800
height=600

black = (0,0,0)

def buffer_newevents(evttype=None,timeout_ms=500,verbose=False):
    '''
    Wait for and return any new events recieved from the buffer between
    calls to this function
    
    timeout    = maximum time to wait in milliseconds before returning
    '''
    global ftc,nEvents # use to store number events processed accross function calls
    if not 'nEvents' in globals(): # first time initialize to events up to now
    	start, nEvents = ftc.poll()

    if verbose:
        print "Waiting for event(s) " + str(evtypes) + " with timeout_ms " + str(timeout_ms)

    start = time.time()
    elapsed_ms = 0
    events=[]
    while len(events)==0 and elapsed_ms<timeout_ms:
        nSamples,curEvents=ftc.wait(-1,nEvents, int(timeout_ms - elapsed_ms))
        if curEvents>nEvents:            
            events = ftc.getEvents([nEvents,curEvents-1])            
            if not evttype is None:
                events = filter(lambda x: x.type in evttype, events)
        nEvents = curEvents # update starting number events (allow for buffer restarts)
        elapsed_ms = (time.time() - start)*1000        
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
screen = pygame.display.set_mode((width,height), 1, 32)
pygame.display.set_caption("Image Salience -- Fragment feedback")

clock = pygame.time.Clock()

# Initialize display state data
surfaces = {}
fragmentSampleMap = {}

# Function to slice image into fragments.
def sliceImage(img,columns,rows):
	slices = []
	(width,height) = img.size

	tile_w = width/columns
	tile_h = height/rows

	for y in range(0, rows):
		row = []
		for x in range(0, columns):
			area = (tile_w*x, tile_h*y, tile_w*x + tile_w, tile_h*y + tile_h)
			fragment = img.crop(area)
			row.append(fragment)
		slices.append(row)

	return slices


def tryOpenImage(name):
	for p in image_paths:
		try:
			image_path = os.path.join(p, name + '.jpg')
			return Image.open(image_path)
		except IOError:
			pass
	raise IOError('Image ' + name + ' could not be found in any of the directories configured in paths. Is the image saved as .jpg?');
	

# Load image, create fragments, convert to surfaces and store.
def loadImage(name):
	img = tryOpenImage(name)
	
	cols = 3;
	rows = 3;

	(img_width, img_height) = img.size
	if img_width > 1.5 * img_height:
		cols = 4

	slices = sliceImage(img, cols, rows)

	for y in range(0, rows):
		for x in range(0, cols):
			# save temp
			tempname = name + '.temp.png';
			slices[y][x].save(tempname)

			# load into pygame surface
			surf = pygame.image.load(tempname)
			surf.set_alpha(255)

			# determine target blit area
			pos_x = (width /cols)*x 
			pos_y = (height/rows)*y
			w = pos_x + (width/cols)
			h = pos_y + (height/rows)

			# Scale image to new dimension
			surf = pygame.transform.scale(surf, (width/cols - 2, height/rows - 2))
	
			# Store in dictionary
			frag_no = x * cols + y + 1
			surfaces[frag_no] = (pygame.Rect(pos_x, pos_y, w,h), surf, []) # Store as (screen_dst, surface, [probabilities])
						

# Function convert prediction to probablity [0-1]
def predictionToProbability(pred):
	if type(pred) is list: pred=pred[0]
	return 1.0 / (1.0 + math.exp(pred))

# Scales alpha [0-1] to (possibly) more useful alpha values [0-1]
def scaleAlpha(alpha):
	return min(alpha * 1.3, 1) #TODO: Determine if we want to change this.

# Receive events from the buffer and process them.
def processBufferEvents():
	global surfaces
	events = buffer_newevents()

	for evt in events:
		print(str(evt.sample) + ": " + str(evt))
		if evt.type == 'stimulus.target.image': # Target image was received, load the image.
			surfaces = {} # Clear surfaces, i.e. reset.
			loadImage(evt.value)

		elif evt.type == 'stimulus.image': # Select the next fragment.
			fragment = int(evt.value.split('/')[1])
			sample = evt.sample
			fragmentSampleMap[sample] = fragment
            
		#elif evt.type == 'stimulus.sequence' and evt.value == 'start':
			#for s in surfaces:
				#s[1].set_alpha(0)

		elif evt.type == 'classifier.prediction':
			# Get fragment from map and delete entry.
			sample = evt.sample
			if not sample in fragmentSampleMap : continue
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
	for i in range(0, len(surfaces)):
		key = i+1
		#print(surfaces)
		#print("key: " + str(key) + ", len(surfaces): " + str(len(surfaces)))
		dst = surfaces[key][0]
		img = surfaces[key][1]
		screen.blit(img, dst)

	# Flip buffers.
	pygame.display.flip()

# Deinitialize
pygame.quit()
