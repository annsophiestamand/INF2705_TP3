#include "scene_stencil.h"

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include "imgui/imgui.h"

#include "utils.h"

#include <iostream>

SceneStencil::SceneStencil(Resources& res, bool& isMouseMotionEnabled)
: Scene(res)
, m_isMouseMotionEnabled(isMouseMotionEnabled)
, m_cameraPosition(0, 1, 0)
, m_cameraOrientation(0)

, m_groundBuffer(GL_ARRAY_BUFFER, 5 * 4 * sizeof(GLfloat), groundData, GL_STATIC_DRAW)
, m_groundIndicesBuffer(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof(GLubyte), indexes, GL_STATIC_DRAW)
, m_groundVao()
, m_groundDraw(m_groundVao, 6)

, m_suzanne("../models/suzanne.obj")
, m_rock("../models/rock.obj")
, m_glass("../models/glass.obj")

, m_groundTexture("../textures/grassSeamless.jpg")
, m_suzanneTexture("../textures/suzanneTextureShade.png")
, m_suzanneWhiteTexture("../textures/suzanneWhite.png")
, m_rockTexture("../textures/rockTexture.png")
, m_glassTexture("../textures/glass.png")
, m_whiteGridTexture("../textures/whiteGrid.png")
{
    m_groundVao.specifyAttribute(m_groundBuffer, 0, 3, 5, 0);
    m_groundVao.specifyAttribute(m_groundBuffer, 1, 2, 5, 3);
    
    m_groundVao.bind();
    m_groundIndicesBuffer.bind();
    m_groundVao.unbind();

    m_groundTexture.setFiltering(GL_LINEAR);
    m_groundTexture.setWrap(GL_REPEAT);
    m_groundTexture.enableMipmap();
    
    m_suzanneTexture.setFiltering(GL_LINEAR);
    m_suzanneTexture.setWrap(GL_CLAMP_TO_EDGE);
    
    m_suzanneWhiteTexture.setFiltering(GL_LINEAR);
    m_suzanneWhiteTexture.setWrap(GL_CLAMP_TO_EDGE);

    m_rockTexture.setFiltering(GL_LINEAR);
    m_rockTexture.setWrap(GL_CLAMP_TO_EDGE);
    
    m_glassTexture.setFiltering(GL_LINEAR);
    m_glassTexture.setWrap(GL_CLAMP_TO_EDGE);
    
    m_whiteGridTexture.setFiltering(GL_LINEAR);
    m_whiteGridTexture.setWrap(GL_REPEAT);
}

SceneStencil::~SceneStencil(){}

void SceneStencil::run(Window& w, double dt)
{
    updateInput(w, dt);

    glm::mat4 proj, view, mvp;
    
    proj = getProjectionMatrix(w);    
    view = getCameraFirstPerson();    
    glm::mat4 projView = proj * view;
    
    // sol
    {
        glm::mat4 modelGround = glm::translate(glm::mat4(1.0f), glm::vec3(0.0f, -0.1f, 0.0f));
        mvp = projView * modelGround;
        m_resources.texture.use();
        m_groundTexture.use();
        glUniformMatrix4fv(m_resources.mvpLocationTexture, 1, GL_FALSE, &mvp[0][0]);
        m_groundDraw.draw();
    }

    // real Suzanne
    glm::mat4 modelSuzanne = glm::translate(glm::mat4(1.0f), glm::vec3(-14.0f, -0.1f, 2.0f));
    {
        glStencilFunc(GL_NOTEQUAL, 1, 0xFF);
        glStencilMask(0x00);

        mvp = projView * modelSuzanne;
        m_resources.texture.use();
        m_suzanneTexture.use();
        glUniformMatrix4fv(m_resources.mvpLocationTexture, 1, GL_FALSE, &mvp[0][0]);
        m_suzanne.draw();
    }

    // roche
    glStencilFunc(GL_ALWAYS, 1, 0xFF);
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);
    glStencilMask(0xFF);

    glm::mat4 modelRock = glm::translate(glm::mat4(1.0f), glm::vec3(-10.0f, 0.4f, 0.0f));
    modelRock = glm::scale(modelRock, glm::vec3(2.0f, 2.0f, 2.0f));
    {
        mvp = projView * modelRock;
        m_resources.texture.use();
        m_rockTexture.use();
        glUniformMatrix4fv(m_resources.mvpLocationTexture, 1, GL_FALSE, &mvp[0][0]);
        m_rock.draw();
    }
    glStencilMask(0x00);

    // simple color Suzanne
    glDisable(GL_DEPTH_TEST); // Désactiver, sinon on va toujours voir la roche par dessus
    {
        glStencilFunc(GL_EQUAL, 1, 0xFF);
        glStencilMask(0x00);

        mvp = projView * modelSuzanne;
        m_resources.simpleColor.use();
        m_whiteGridTexture.use();
        glUniformMatrix4fv(m_resources.mvpLocationSimpleColor, 1, GL_FALSE, &mvp[0][0]);
        m_suzanne.draw();
    }

    glEnable(GL_DEPTH_TEST);
    glStencilFunc(GL_ALWAYS, 0, 0xFF);
    glStencilMask(0xFF);
    glClear(GL_STENCIL_BUFFER_BIT);

    // monkeys statues
    {
        const std::vector<glm::vec3> monkeyPositions = {
            {12.0f, -0.1f,  4.0f},
            {12.0f, -0.1f,  0.0f},
            {12.0f, -0.1f, -4.0f}
        };
        m_resources.texture.use();
        m_suzanneWhiteTexture.use();
        glm::mat4 modelStatue;

        for (const auto& pos : monkeyPositions) {
            modelStatue = glm::translate(glm::mat4(1.0f), pos);
            modelStatue = glm::rotate(modelStatue, glm::radians(-90.0f), glm::vec3(0.0f, 1.0f, 0.0f));
        
            glStencilFunc(GL_NOTEQUAL, 1, 0xFF);
            glStencilMask(0x00);
        
            mvp = projView * modelStatue;
            glUniformMatrix4fv(m_resources.mvpLocationTexture, 1, GL_FALSE, &mvp[0][0]);
        
            m_suzanne.draw();
        }
    }
    
    // vitre
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);

    {
        glm::mat4 modelGlass = glm::translate(glm::mat4(1.0f), glm::vec3(10.0f, -0.1f, 0.0f));
        modelGlass = glm::scale(modelGlass, glm::vec3(2.0f, 2.0f, 2.0f));

        mvp = projView * modelGlass;
        m_resources.texture.use();
        m_glassTexture.use();
        glUniformMatrix4fv(m_resources.mvpLocationTexture, 1, GL_FALSE, &mvp[0][0]);
        m_glass.draw();
    }
    
    glDisable(GL_BLEND);
    glEnable(GL_CULL_FACE);
}

void SceneStencil::updateInput(Window& w, double dt)
{
    // Mouse input
    int x = 0, y = 0;
    if (m_isMouseMotionEnabled)
        w.getMouseMotion(x, y);
    const float MOUSE_SENSITIVITY = 0.1;
    float cameraMouvementX = y * MOUSE_SENSITIVITY;
    float cameraMouvementY = x * MOUSE_SENSITIVITY;;
    
    const float KEYBOARD_MOUSE_SENSITIVITY = 1.5f;
    if (w.getKeyHold(Window::Key::UP))
        cameraMouvementX -= KEYBOARD_MOUSE_SENSITIVITY;
    if (w.getKeyHold(Window::Key::DOWN))
        cameraMouvementX += KEYBOARD_MOUSE_SENSITIVITY;
    if (w.getKeyHold(Window::Key::LEFT))
        cameraMouvementY -= KEYBOARD_MOUSE_SENSITIVITY;
    if (w.getKeyHold(Window::Key::RIGHT))
        cameraMouvementY += KEYBOARD_MOUSE_SENSITIVITY;
    
    m_cameraOrientation.y -= cameraMouvementY * dt;
    m_cameraOrientation.x -= cameraMouvementX * dt;

    // Keyboard input
    glm::vec3 positionOffset = glm::vec3(0.0);
    const float SPEED = 10.f;
    if (w.getKeyHold(Window::Key::W))
        positionOffset.z -= SPEED;
    if (w.getKeyHold(Window::Key::S))
        positionOffset.z += SPEED;
    if (w.getKeyHold(Window::Key::A))
        positionOffset.x -= SPEED;
    if (w.getKeyHold(Window::Key::D))
        positionOffset.x += SPEED;
        
    if (w.getKeyHold(Window::Key::Q))
        positionOffset.y -= SPEED;
    if (w.getKeyHold(Window::Key::E))
        positionOffset.y += SPEED;

    positionOffset = glm::rotate(glm::mat4(1.0f), m_cameraOrientation.y, glm::vec3(0.0, 1.0, 0.0)) * glm::vec4(positionOffset, 1);
    m_cameraPosition += positionOffset * glm::vec3(dt);
}

