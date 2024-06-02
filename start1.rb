require 'ruby2d'  # Importerar Ruby 2D-biblioteket för grafisk hantering

# Ställer in fönstrets titel
set title: "Mini Golf Start Page"
# Ställer in fönstrets bakgrundsfärg
set background: 'white'
# Ställer in fönstrets bredd
set width: 800
# Ställer in fönstrets höjd
set height: 600

# Konstanter
BALL_RADIUS = 10  # Bollens radie
HOLE_RADIUS = 15  # Hålets radie
OBSTACLE_SIZE = 50  # Hinderstorlek
DRAG_MULTIPLIER = 1.6  # Sensitivitet för att dra
MAX_SHOT_SPEED = 10  # Maximal skotthastighet
DAMPING_FACTOR = 0.977  # Dämpningsfaktor för att kontrollera avmattning
STOP_THRESHOLD = 0.5  # Tröskel för att stoppa bollen
DARK_GREEN = '#006400'  # Mörkgrön färg
BUNKER_RADIUS = 30  # Bunker radie

# För att rita menyn
game_started = false  # Variabel för att kontrollera om spelet har startat

# Spårar musposition
mouse_down = nil  # Musens position när knappen trycks ned
mouse_up = nil  # Musens position när knappen släpps
ball_in_motion = false  # Variabel för att kontrollera om bollen är i rörelse
shot_velocity = [0, 0]  # Variabel för att lagra skotthastighet

######## STARTMENY ###########
start_button = Rectangle.new(  # Skapar en rektangel för startknappen
  x: 150, y: 250,
  width: 550, height: 100,
  color: 'green'
)

start_text = Text.new(  # Skapar text för startknappen
  "STARTA GENOM ATT TRYCKA SPACE",
  x: 165, y: 280,
  size: 30,
  color: 'white'
)

###### bana1 #########
# Skapar rektanglar för hinder och bunkrar
motstånd1 = Rectangle.new(x: 0, y: 0, width: 790, height: 50,  color: DARK_GREEN)
motstånd2 = Rectangle.new(x: 0, y: 550, width: 790, height: 50,  color: DARK_GREEN)
bunker1 = Circle.new(x: 650, y: 250, radius: BUNKER_RADIUS, color: 'yellow')
bunker2 = Circle.new(x: 550, y: 380, radius: BUNKER_RADIUS, color: 'yellow')
bunker3 = Circle.new(x: 500, y: 250, radius: BUNKER_RADIUS, color: 'yellow')
bunker4 = Circle.new(x: 650, y: 400, radius: BUNKER_RADIUS, color: 'yellow')
hole = Circle.new(x: 700, y: 300, radius: HOLE_RADIUS, color: 'black')

# Skapar en array med rektanglar för hinder
obstacles = [
  Rectangle.new(x: 0, y: 0, width: 800, height: 10, color: 'brown'),
  Rectangle.new(x: 0, y: 0, width: 10, height: 600, color: 'brown'),
  Rectangle.new(x: 0, y: 590, width: 800, height: 10, color: 'brown'),
  Rectangle.new(x: 790, y: 0, width: 10, height: 600, color: 'brown'),
  Rectangle.new(x: 200, y: 200, width: OBSTACLE_SIZE, height: OBSTACLE_SIZE, color: 'brown'),
  Rectangle.new(x: 300, y: 420, width: OBSTACLE_SIZE, height: OBSTACLE_SIZE, color: 'brown'),
  Rectangle.new(x: 500, y: 100, width: OBSTACLE_SIZE, height: OBSTACLE_SIZE, color: 'brown'),
  Rectangle.new(x: 380, y: 300, width: OBSTACLE_SIZE, height: OBSTACLE_SIZE, color: 'brown'),
  Rectangle.new(x: 100, y: 480, width: OBSTACLE_SIZE, height: OBSTACLE_SIZE, color: 'brown'),
  Rectangle.new(x: 600, y: 480, width: OBSTACLE_SIZE, height: OBSTACLE_SIZE, color: 'brown'),
  Rectangle.new(x: 350, y: 180, width: OBSTACLE_SIZE, height: OBSTACLE_SIZE, color: 'brown'),
]

# Skapar en sprite för explosionseffekten
boom = Sprite.new(
  'boom.png',
  clip_width: 127,
  x: 635, y: 230,
  time: 75
)

# Skapar en cirkel för bollen
ball = Circle.new(x: 100, y: 350, radius: BALL_RADIUS, color: 'white')

####### SPELFUNKTIONER ###########

# Återställer bollens position
def reset_ball(ball)
  ball.x = 100
  ball.y = 350
end

# Beräknar skotthastighet
def calculate_velocity(mouse_down, mouse_up)
  shot_dx = mouse_up[0] - mouse_down[0]
  shot_dy = mouse_up[1] - mouse_down[1]
  magnitude = Math.sqrt(shot_dx**2 + shot_dy**2)
  normalized_dx = shot_dx / magnitude
  normalized_dy = shot_dy / magnitude
  shot_speed = [magnitude / 10, MAX_SHOT_SPEED].min  # Justerar känslighet och maxhastighet
  [-normalized_dx * shot_speed, -normalized_dy * shot_speed]  # Inverterar hastigheten
end

# Kontrollerar kollision med hinder
def collides_with_obstacle?(ball, obstacle)
  obstacle_center_x = obstacle.x + obstacle.width / 2
  obstacle_center_y = obstacle.y + obstacle.height / 2
  distance_x = (ball.x - obstacle_center_x).abs
  distance_y = (ball.y - obstacle_center_y).abs

  if distance_x > (obstacle.width / 2.0 + BALL_RADIUS)
    closest_x = obstacle.x + obstacle.width / 2.0
  else
    closest_x = [ball.x, obstacle.x].max
    closest_x = [closest_x, obstacle.x + obstacle.width].min
  end

  if distance_y > (obstacle.height / 2.0 + BALL_RADIUS)
    closest_y = obstacle.y + obstacle.height / 2.0
  else
    closest_y = [ball.y, obstacle.y].max
    closest_y = [closest_y, obstacle.y + obstacle.height].min
  end

  distance_x = ball.x - closest_x
  distance_y = ball.y - closest_y
  distance = Math.sqrt(distance_x**2 + distance_y**2)

  distance <= BALL_RADIUS
end

# Kontrollerar om bollen har nått hålet
def reached_hole?(ball, hole)
  distance = Math.sqrt((ball.x - hole.x) ** 2 + (ball.y - hole.y) ** 2)
  distance <= BALL_RADIUS + HOLE_RADIUS
end

# Kontrollerar om bollen har nått bunkern
def reached_bunker?(ball, bunker)
  distance = Math.sqrt((ball.x - bunker.x) ** 2 + (ball.y - bunker.y) ** 2)
  distance <= BALL_RADIUS + BUNKER_RADIUS
end

# Beräknar hastighetsmagnitude
def velocity_magnitude(velocity)
  Math.sqrt(velocity[0]**2 + velocity[1]**2)
end

# Begränsningsfunktion för att hålla värde inom ett intervall
def clamp(value, min, max)
  if value < min
    min
  elsif value > max
    max
  else
    value
  end
end

########## TANGENTBORDSLYSSNARE #######################
on :key_down do |event|
  if event.key == 'space'  # Om mellanslag trycks
    start_button.remove  # Ta bort startknappen
    start_text.remove  # Ta bort starttexten
    game_started = !game_started  # Växla spelstatus
  end
end

on :mouse_down do |event|
  if !ball_in_motion  # Om bollen inte är i rörelse
    mouse_down = [event.x, event.y]  # Spara musens position
  end
end

on :mouse_up do |event|
  if !ball_in_motion  # Om bollen inte är i rörelse
    mouse_up = [event.x, event.y]  # Spara musens position
    shot_velocity = calculate_velocity(mouse_down, mouse_up)  # Beräkna skotthastighet
    ball_in_motion = true  # Sätt bollen i rörelse
  end
end

on :key_down do |event|
  reset_ball(ball) if event.key == 'r' && !ball_in_motion  # Återställ bollen om 'r' trycks
end

########## SPELLOOP #############
update do
  if game_started  # Om spelet har startat
    set background: 'green'  # Sätt bakgrundsfärgen till grön
    hole.add  # Lägg till hålet
    bunker1.add  # Lägg till bunker1
    bunker2.add  # Lägg till bunker2
    bunker3.add  # Lägg till bunker3
    bunker4.add  # Lägg till bunker4
    motstånd1.add  # Lägg till motstånd1
    motstånd2.add  # Lägg till motstånd2
    obstacles.each(&:add)  # Lägg till alla hinder
    ball.add  # Lägg till bollen
    start_button.remove  # Ta bort startknappen
    start_text.remove  # Ta bort starttexten
  else
    set background: 'white'  # Sätt bakgrundsfärgen till vit
    hole.remove  # Ta bort hålet
    ball.remove  # Ta bort bollen
    bunker1.remove  # Ta bort bunker1
    bunker2.remove  # Ta bort bunker2
    bunker3.remove  # Ta bort bunker3
    bunker4.remove  # Ta bort bunker4
    motstånd1.remove  # Ta bort motstånd1
    motstånd2.remove  # Ta bort motstånd2
    obstacles.each(&:remove)  # Ta bort alla hinder
    start_button.add  # Lägg till startknappen
    start_text.add  # Lägg till starttexten
  end

  if ball_in_motion  # Om bollen är i rörelse
    shot_velocity[0] *= DAMPING_FACTOR  # Tillämpa dämpning på x-hastigheten
    shot_velocity[1] *= DAMPING_FACTOR  # Tillämpa dämpning på y-hastigheten

    if ball.y < 50 || ball.y > 550  # Om bollen är nära kanterna
      shot_velocity[0] *= 0.95  # Minska x-hastigheten
      shot_velocity[1] *= 0.95  # Minska y-hastigheten
    end

    ball.x += shot_velocity[0]  # Uppdatera bollens x-position
    ball.y += shot_velocity[1]  # Uppdatera bollens y-position

    obstacles.each do |obstacle|
      if collides_with_obstacle?(ball, obstacle)  # Kontrollera kollision med hinder
        closest_x = clamp(ball.x, obstacle.x, obstacle.x + obstacle.width)  # Närmaste x-position
        closest_y = clamp(ball.y, obstacle.y, obstacle.y + obstacle.height)  # Närmaste y-position
        distance_x = ball.x - closest_x  # Avstånd i x
        distance_y = ball.y - closest_y  # Avstånd i y
        distance = Math.sqrt(distance_x**2 + distance_y**2)  # Totalt avstånd
        normal_x = distance_x / distance  # Normaliserad x
        normal_y = distance_y / distance  # Normaliserad y
        dot_product = shot_velocity[0] * normal_x + shot_velocity[1] * normal_y  # Punktprodukt
        reflection_x = shot_velocity[0] - 2 * dot_product * normal_x  # Reflekterad x
        reflection_y = shot_velocity[1] - 2 * dot_product * normal_y  # Reflekterad y
        shot_velocity = [reflection_x, reflection_y]  # Uppdatera skotthastighet
      end
    end

    if reached_hole?(ball, hole)  # Om bollen har nått hålet
      boom.play  # Spela explosionseffekten
      reset_ball(ball)  # Återställ bollen
      ball_in_motion = false  # Stoppbollens rörelse
    end

    if velocity_magnitude(shot_velocity) < STOP_THRESHOLD  # Om bollen är tillräckligt långsam
      ball_in_motion = false  # Tillåt ny skott
    end
  end
end

show  # Visa fönstret
