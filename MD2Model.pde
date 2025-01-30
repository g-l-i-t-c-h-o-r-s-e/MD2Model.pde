/*******************************************************************************
 * Ported MD2 Loader Example for Processing 4
 * Original by Marcello Bastea-Forte (http://marcello.cellosoft.com/)
 * Ported by Pandela
 * Source: http://web.archive.org/web/20101029202114/http://www.cs.unm.edu/~cello/processing/md2loader2/md2loader2.pde
 *
 *  Contains the following modules:

 * MD2 Loader - loads, displays, animates MD2 (Quake 2) models for Processing
 *   - based on C++ MD2 loader by DigiBen (http://www.gametutorials.com/Tutorials/opengl/OpenGL_Pg4.htm)
 *   - heavily adapted and completely rewritten in Processing by Marcello (http://marcello.cellosoft.com/) 
 ********************************************************************************/

int readInt4(byte[] b, int o) {
  return (0xFF&b[o++])|((0xFF&b[o++])<<8)|((0xFF&b[o++])<<16)|((0xFF&b[o])<<24);
}
float readFloat4(byte[] b, int o) {
  return Float.intBitsToFloat(readInt4(b,o));
}
short readShort2(byte[] b, int o) {
  return (short)((0xFF&b[o++])|((0xFF&b[o++])<<8));
}
String readString(byte[] b, int o, int len) {
  String s = "";
  while (len>=0 && b[o]!=0) {
    s+=char(b[o++]);
    len--;
  }
  return s;
}

// This holds the header information that is read in at the beginning of the file
class MD2Header { 
   int magic;        // This is used to identify the file
   int version;        // The version number of the file (Must be 8)
   int skinWidth;      // The skin width in pixels
   int skinHeight;      // The skin height in pixels
   int frameSize;      // The size in bytes the frames are
   int numSkins;      // The number of skins associated with the model
   int numVertices;      // The number of vertices (constant for each frame)
   int numTexCoords;      // The number of texture coordinates
   int numTriangles;      // The number of faces (polygons)
   int numGlCommands;      // The number of gl commands
   int numFrames;      // The number of animation frames
   int offsetSkins;      // The offset in the file for the skin data
   int offsetTexCoords;      // The offset in the file for the texture data
   int offsetTriangles;      // The offset in the file for the face data
   int offsetFrames;      // The offset in the file for the frames data
   int offsetGlCommands;    // The offset in the file for the gl commands data
   int offsetEnd;      // The end of the file offset
   MD2Header(byte[] b) {
     int i=0;
     magic            = readInt4(b,i); i+=4;
     version          = readInt4(b,i); i+=4;
     skinWidth        = readInt4(b,i); i+=4;
     skinHeight       = readInt4(b,i); i+=4;
     frameSize        = readInt4(b,i); i+=4;
     numSkins         = readInt4(b,i); i+=4;
     numVertices      = readInt4(b,i); i+=4;
     numTexCoords     = readInt4(b,i); i+=4;
     numTriangles     = readInt4(b,i); i+=4;
     numGlCommands    = readInt4(b,i); i+=4;
     numFrames        = readInt4(b,i); i+=4;
     offsetSkins      = readInt4(b,i); i+=4;
     offsetTexCoords  = readInt4(b,i); i+=4;
     offsetTriangles  = readInt4(b,i); i+=4;
     offsetFrames     = readInt4(b,i); i+=4;
     offsetGlCommands = readInt4(b,i); i+=4;
     offsetEnd        = readInt4(b,i); i+=4;
   }
}


// This is used to store the vertices that are read in for the current frame
class MD2AliasTriangle {
   int vertex[] = new int[3];
   int lightNormalIndex;
   MD2AliasTriangle(byte[] b, int o) {
     vertex[0] = 0xFF&b[o];
     vertex[1] = 0xFF&b[o+1];
     vertex[2] = 0xFF&b[o+2];
     lightNormalIndex = 0xFF&b[o+3];
   }
   int getSize() { return 4; }
};

// This stores the normals and vertices for the frames
class MD2Triangle {
   float vertex[] = new float[3];
   float normal[] = new float[3];
   int getSize() { return 4 * 6; }
};

// This stores the indices into the vertex and texture coordinate arrays
class MD2Face {
   short vertexIndices[] = new short[3];
   short textureIndices[] = new short[3];
   
   MD2Face(byte[] b, int o) {
     vertexIndices[0] = readShort2(b,o); o+=2;
     vertexIndices[1] = readShort2(b,o); o+=2;
     vertexIndices[2] = readShort2(b,o); o+=2;
     textureIndices[0] = readShort2(b,o); o+=2;
     textureIndices[1] = readShort2(b,o); o+=2;
     textureIndices[2] = readShort2(b,o); o+=2;
   }
   int getSize() { return 2 * 6; }
};

// This stores UV coordinates
class MD2TexCoord
{
   short u, v;
   MD2TexCoord(byte[] b, int o) {
     u = readShort2(b,o);
     v = readShort2(b,o+2);
   }
   int getSize() { return 4; }
};

// This stores the animation scale, translation and name information for a frame, plus verts
class MD2AliasFrame
{
   float scale[] = new float[3];
   float translate[] = new float[3];
   String name;
   MD2AliasTriangle aliasVertices[];
   MD2AliasFrame(byte[] b, int o, int size) {
     scale[0] = readFloat4(b, o); o+=4; size -= 4;
     scale[1] = readFloat4(b, o); o+=4; size -= 4;
     scale[2] = readFloat4(b, o); o+=4; size -= 4;
     translate[0] = readFloat4(b, o); o+=4; size -= 4;
     translate[1] = readFloat4(b, o); o+=4; size -= 4;
     translate[2] = readFloat4(b, o); o+=4; size -= 4;
     name = readString(b, o, 16); o+=16; size -= 16;
     
     int aliascount = size / 4;
     aliasVertices = new MD2AliasTriangle[aliascount];
     for (int i = 0; i<aliascount; i++) {
       aliasVertices[i] = new MD2AliasTriangle(b, o);
       o+=4;
     }
   }
   int getSize() {
     return 4*6 + 16 + aliasVertices[0].getSize() * aliasVertices.length;
   }
}

// This stores the frames vertices after they have been transformed
class MD2Frame {
   String name;
   MD2Triangle vertices[];
   MD2Frame(String name, int verticecount) {
     this.name = name;
     vertices = new MD2Triangle[verticecount];
     for (int i=0; i<vertices.length; i++)
       vertices[i] = new MD2Triangle();
   }
};
class MD2Animation {
  String name;
  int startFrame;
  int endFrame;
}

class MD2Model {
  MD2Header    header;      // The header data
  String       skins[];      // The skin data
  MD2TexCoord  texCoords[];    // The texture coordinates
  MD2Face      triangles[];    // Face index information
  MD2Frame     frames[];    // The frames of animation (vertices)
  MD2Animation animations[];
  MD2Triangle[][] originalVertices;
  
  PImage       texture;
  
    //boolean loopAnimation = true; // Field to control looping
    boolean pingPongEffect = false; //
  
  MD2Model(String file, PImage texture) {
    byte data[] = loadBytes(file);

    header = new MD2Header(data);
    

    if (header.version != 8)
      println("Error: version not 8");


    ReadMD2Data(data);
    
    BuildMD2Animations();
    if (animations.length > 0) {
        currentFrame = animations[0].startFrame;
        nextFrame = animations[0].startFrame + 1;
    }
    ComputeNormals();

    this.texture = texture;
  }

  void ReadMD2Data(byte data[]) {
    skins     = new String     [header.numSkins];
    texCoords = new MD2TexCoord [header.numTexCoords];
    triangles = new MD2Face     [header.numTriangles];
    frames    = new MD2Frame    [header.numFrames];

    int o = header.offsetSkins;
    for (int i=0; i<skins.length; i++) {
      skins[i] = readString(data,o,64);
      o+=64;
    }
    
    o = header.offsetTexCoords;
    for (int i=0; i<texCoords.length; i++)
      o+= (texCoords[i] = new MD2TexCoord(data, o)).getSize();
    
    o = header.offsetTriangles;
    for (int i=0; i<triangles.length; i++)
      o += (triangles[i] = new MD2Face(data, o)).getSize();
    
    o = header.offsetFrames;
    for (int i=0; i<frames.length; i++) {
      MD2AliasFrame frame = new MD2AliasFrame(data, o, header.frameSize);
      o += frame.getSize(); 
      
      frames[i] = new MD2Frame(frame.name, header.numVertices);
      
      MD2Triangle vertices[] = frames[i].vertices;
      
      for (int j=0; j < header.numVertices; j++) {
        frames[i].vertices[j].vertex[0] = frame.aliasVertices[j].vertex[0] * frame.scale[0] + frame.translate[0];
        frames[i].vertices[j].vertex[2] = frame.aliasVertices[j].vertex[1] * frame.scale[1] + frame.translate[1];
        frames[i].vertices[j].vertex[1] = -(frame.aliasVertices[j].vertex[2] * frame.scale[2] + frame.translate[2]);
      } 
    }
      //wacky stuff
      originalVertices = new MD2Triangle[frames.length][];
      for (int i = 0; i < frames.length; i++) {
          originalVertices[i] = new MD2Triangle[frames[i].vertices.length];
          for (int j = 0; j < frames[i].vertices.length; j++) {
              originalVertices[i][j] = new MD2Triangle();
              System.arraycopy(frames[i].vertices[j].vertex, 0, originalVertices[i][j].vertex, 0, 3);
          }
      }
  }
  
  void BuildMD2Animations() {
    Vector animations = new Vector();
    MD2Animation animation = null;
    String lastName = "";
    for (int i=0; i<frames.length; i++) {
      String s = frames[i].name;
      for (int j=s.length()-2; j<s.length(); j++) {
        char c = s.charAt(j);
        if (c>='0' && c<='9') {
          s = s.substring(0,j);
        }
      }
      
      if (!s.equals(lastName) || i==frames.length-1) {
        if (lastName.length()>0) {
          animation.name = lastName;
          animation.endFrame = i;
          animations.addElement(animation);
        }
        animation = new MD2Animation();
        animation.startFrame = i;
      }
      lastName = s;
    }
    this.animations = new MD2Animation[animations.size()];
    for (int i=0; i<this.animations.length; i++)
      this.animations[i] = (MD2Animation)animations.elementAt(i);
  }

  void setAnimation(int animation) {
      if (animations.length == 0) {
          println("No animations available for this model.");
          // Handle models with no animations (e.g., display in a default pose)
          return;
      }
      if (animation < 0 || animation >= animations.length) {
          println("Animation index is out of bounds.");
          return;
      }
  
  
      // Check if the current animation is already set to the requested animation
      if (currentAnimation == animation) return;
  
      currentAnimation = animation;
      nextFrame = animations[animation].startFrame;
      elapsedTime = 0;
  }

  
  int currentAnimation = 0;
  
  int lastFrame = 0;
  int currentFrame = 0;
  int nextFrame = 0;
  int nextNextFrame = 0;

  void update() {
      if (animations.length == 0) {
          return; // No animations available
      }
  
      MD2Animation anim = animations[currentAnimation];
      elapsedTime += (millis() - lastTime);
      lastTime = millis();
  
      float frameUpdateInterval = 1000 / max(1, animationSpeed); // Prevent division by zero
  
      if (elapsedTime >= frameUpdateInterval) {
          elapsedTime %= frameUpdateInterval; // Retain the remainder to keep the animation smooth
  
          // Check if there is only one frame in the animation
          if (anim.startFrame == anim.endFrame + 1) {
              // For a single frame, keep the current, next, and last frames the same
              currentFrame = nextFrame = lastFrame = anim.startFrame;
          } else if (pingPongEffect) {
              // Ping Pong Effect for more than one frame
              if (nextFrame > lastFrame) {
                  // Moving forward
                  lastFrame = currentFrame;
                  currentFrame = nextFrame;
                  nextFrame++;
  
                  if (nextFrame >= anim.endFrame) {
                      // Reverse direction at the end of the animation
                      nextFrame = anim.endFrame - 2;
                      lastFrame = anim.endFrame - 1;
                  }
              } else {
                  // Moving backward
                  lastFrame = currentFrame;
                  currentFrame = nextFrame;
                  nextFrame--;
  
                  if (nextFrame <= anim.startFrame + 1) {
                      // Reverse direction at the start of the animation
                      nextFrame = anim.startFrame + 2;
                      lastFrame = anim.startFrame + 1;
                  }
              }
          } else {
              // Normal animation loop logic
              lastFrame = currentFrame;
              currentFrame = nextFrame;
              nextFrame++;
  
              // Skip frame 0, start from frame 1
              if (nextFrame >= anim.endFrame) {
                  nextFrame = anim.startFrame + 1;
              }
          }
  
          // Ensure nextNextFrame is within bounds for animations with more than one frame
          if (anim.startFrame != anim.endFrame - 1) {
              nextNextFrame = nextFrame + (nextFrame - lastFrame > 0 ? 1 : -1);
              if (nextNextFrame <= anim.startFrame + 1 || nextNextFrame >= anim.endFrame) {
                  nextNextFrame = currentFrame;
              }
          }
      }
  
      // Calculate interpolation factor
      t = (float)elapsedTime / frameUpdateInterval;
  }


  float t = 0;
  void draw() {
    beginShape(TRIANGLES);
    texture(texture);
      for (int j = 0; j<triangles.length; j++) {
        for (int v = 0; v < 3; v++) {
          // Get the index for each point of the face
          int vi = triangles[j].vertexIndices[v];
          int ti = triangles[j].textureIndices[v];
           
          float v0[] = frames[lastFrame].vertices[vi].vertex;
          float v1[] = frames[currentFrame].vertices[vi].vertex;
          float v2[] = frames[nextFrame].vertices[vi].vertex;
          float v3[] = frames[nextNextFrame].vertices[vi].vertex;
          
          // thanks to entheh for the following code
          float p[] = new float[3];
          float q[] = new float[3];
          float r[] = new float[3];
          float s[] = new float[3];
          
          for (int i=0; i<3; i++) {
            float a = v0[i], b = v1[i], c = v2[i], d = v3[i];
            p[i] = b;
            q[i] = 0.5f * (c - a);
            r[i] = a - 2.5f*b + 2*c - 0.5f*d;
            s[i] = 1.5f * (b - c) + 0.5f * (d - a);
          }
          
          
          vertex(p[0] * scaleX + t * (q[0] + t * (r[0] + t * s[0])),
                 p[1] * scaleY + t * (q[1] + t * (r[1] + t * s[1])),
                 p[2] * scaleZ + t * (q[2] + t * (r[2] + t * s[2])),
                 texCoords[ti].u,
                 texCoords[ti].v);

        }
      }
    endShape();
  }
  float elapsedTime = 0;
  float lastTime = 0;
  float animationSpeed = 5;
  
  float ReturnCurrentTime() {
    float time = millis();
    elapsedTime = time - lastTime;

    float t = elapsedTime / (1000 / animationSpeed);
    
    if (elapsedTime >= 1000 / animationSpeed) {
      lastFrame = currentFrame;
      currentFrame = nextFrame;
      lastTime = time;
    }
    return t;
  }
  
  void ComputeNormals() {
  }

 
  float scaleX = 1.0;
  float scaleY = 1.0;
  float scaleZ = 1.0;
 
  void setScale(float x, float y, float z) {
  scaleX = x;
  scaleY = y;
  scaleZ = z;
  }
  
  void printAnimations() {
      if (animations == null || animations.length == 0) {
          println("No animations available.");
          return;
      }
      
      println("Available Animations:");
      for (int i = 0; i < animations.length; i++) {
          MD2Animation anim = animations[i];
          println(i + ": " + anim.name + " (Frames: " + anim.startFrame + " to " + anim.endFrame + ")");
      }
  }
}
