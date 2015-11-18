bufferpath = "../../dataAcq/buffer/python"

import os, sys, pygame, random, math, time
sys.path.append(os.path.dirname(__file__)+bufferpath)
import FieldTrip
from PIL import Image

# Value definitions
image_paths = ['./pictures/targets', './pictures/distractors', './pictures/test', './pictures/training', './pictures/faces']

hostname='localhost'
port=1972

width=800
height=600

cols = 4
rows = 3

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
        print("Waiting for event(s) " + str(evtypes) + " with timeout_ms " + str(timeout_ms))

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
pygame.display.set_caption("Image Salience -- Target feedback")
font = pygame.font.SysFont("monospace", 18)

clock = pygame.time.Clock()

# Initialize display state data
surfaces = []		# Stored as [(screen_dst, surface)]
imageProbabilities = {} # Stored as {image => [probabilities]}
imageSampleMap = {}     # Stored as {sample => image}
loadedImages = {}       # Stored as {image => surface}

# Number of predictions received.
numPredictions = 0

# Tries to load an image from one of the configured directories.
def tryOpenImage(name):
	for p in image_paths:
		try:
			image_path = os.path.join(p, name + '.jpg')
			return pygame.image.load(image_path)
		except:
			pass
	raise IOError('Image ' + name + ' could not be found in any of the directories configured in paths. Is the image saved as .jpg?');
	
# Loads an image from either the cache or from disk.
def loadImage(name):
	if name in loadedImages:
		return loadedImages[name]
	else:
		img = tryOpenImage(name)
		loadedImages[name] = img
		return img


# Function convert prediction to probablity [0-1]
def predictionToProbability(pred):
	if type(pred) is list: pred=pred[0]
	return 1.0 / (1.0 + math.exp(pred))

# Scales alpha [0-1] to (possibly) more useful alpha values [0-1]
def scaleAlpha(alpha):
	return min(alpha * 1.3, 1) #TODO: Determine if we want to change this.


def avg(l):
	return sum(l) / len(l)

# Receive events from the buffer and process them.
def processBufferEvents():
	global surfaces, done
	global imageSampleMap
	global numPredictions
	global imageProbabilities
	events = buffer_newevents()

	for evt in events:
		print(str(evt.sample) + ": " + str(evt))

		if evt.type == 'startPhase.cmd' and evt.value == 'exit' : # finish
			done=True
			
		elif evt.type == 'stimulus.image': # Select the next fragment.
			image = evt.value.split('/')[0]
			sample = evt.sample
			imageSampleMap[sample] = image
			
		# When a new feedback phase starts, clear probabilities and sample maps.
		elif (evt.type == 'startPhase.cmd' and evt.value == 'epochfeedback') or evt.type == 'stimulus.target.image':
			imageProbabilities = {}
			imageSampleMap = {}
			print('Cleared probabilities')

		elif evt.type == 'classifier.prediction':
			# Get image from map and delete entry.
			sample = evt.sample
			if not sample in imageSampleMap : continue
			image = imageSampleMap[sample]
			del imageSampleMap[sample]

			# Calculate prediction and add to imageProbabilities
			pred = evt.value
			prob = predictionToProbability(pred)
			if not image in imageProbabilities:
				imageProbabilities[image] = [prob]
			else:
				imageProbabilities[image].append(prob)

			numPredictions += 1

			# Update display every 10 predictions = 2 seconds.
			if numPredictions % 10 == 0: 
				# Remove candidates that have less than two samples.
				sortedImages = [img for img in imageProbabilities.items() if len(img[1]) > 2]

				# Sort by average probability, highest to lowest.
				sortedImages = sorted(sortedImages, key = lambda x: avg(x[1]), reverse = True)

				# Display top (rows*cols).
				top_nine = sortedImages[:(rows*cols)]
				update_surfaces(top_nine)


# Updates the surfaces array, which contains the surfaces to be drawn.
def update_surfaces(images): # images = [(image, [probabilities])], sorted by avg(probabilities), highest to lowest.
	global surfaces
	img_width = width / cols
	img_height = height / rows

	surfaces = []

	for x in range(0, cols):
		for y in range(0, rows):
			# Get some values.
			idx = cols * y + x
			if len(images) <= idx: continue # This means there are less images than cells, just pass.

			img = images[idx]
			img_name = img[0]
			img_ps = img[1]

			# Get surface and calculate location.
			surf = loadImage(img_name)
			target_dst = pygame.Rect(img_width * x, img_height * y, img_width, img_height)

			# Set surface properties (size and alpha)
			surf = pygame.transform.scale(surf, (img_width-3, img_height-3))
			surf.set_alpha(scaleAlpha(sum(img_ps)/len(img_ps)) * 255)
			
			rank_surf = font.render("rank: " + str(idx+1), 1, (255,255,255), (0,0,0))
			p_surf = font.render(str(sum(img_ps)/len(img_ps)), 1, (255, 255, 255), (0,0,0))

			# save.
			surfaces.append((target_dst, surf, rank_surf, p_surf))

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
	for surf in surfaces:
		dst = surf[0]
		img = surf[1]
		rank_surf = surf[2]
		p_surf = surf[3]
		screen.blit(img, dst)
		screen.blit(rank_surf, dst)
		#screen.blit(pygame.Rect(dst.x, dst.y + 20, dst.width, dst.height - 20))

	# Flip buffers.
	pygame.display.flip()

# Deinitialize
pygame.quit()
