import sys, pygame, random

# Value definitions
width=800
height=600

black = (0,0,0)

# Initialize pygame
pygame.init()
screen = pygame.display.set_mode((width,height),  1, 32)
pygame.display.set_caption("Music Brain Reading -- Feedback")

myfont = pygame.font.SysFont('Verdana', 15)
clock = pygame.time.Clock()

# Initialize surfaces
surfaces = []
for i in range(0,7):
	i_f = i+1;
	txt = 'Label ' + str(i_f) + ': ' + str(1.0/i_f)
	color = (255, 255 * (1.0/i_f), 255*(1.0/i_f))
	label = myfont.render(txt, 1, color).convert() # labels are drawn incorrectly, should work properly for images.

	surfaces.append((label, 1.0));

# Update transparencies of surfaces.
def update_surfaces():
	for i in range(0,7):
		surfaces[i] = (surfaces[i][0], random.random()); # Replace with buffer_bci event wait.

# Event loop
done = False
while not done:
	for event in pygame.event.get():
		if event.type == pygame.QUIT:
			done=True

	screen.fill(black)

	# Display surfaces.
	for i in range(0,7):
		surface = surfaces[i]
		displ = surface[0]
		displ.set_alpha(255*surface[1])

		x = (i/2)*(width/4)
		y = ((i%2)*(height/2))

		screen.blit(displ, (x,y))

	pygame.display.flip()

	# Limit FPS to simulate waiting for buffer_bci events.
	clock.tick(1) 
	update_surfaces()

# Deinitialize
pygame.quit()
