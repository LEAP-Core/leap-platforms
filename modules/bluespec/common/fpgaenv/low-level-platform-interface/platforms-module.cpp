#include <cstdlib>
#include <assert.h>
#include <iostream>

#include "platforms-module.h"

using namespace std;

// constructors
PLATFORMS_MODULE_CLASS::PLATFORMS_MODULE_CLASS()
{
    parent   = NULL;
    next     = NULL;
    prev     = NULL;
    children = NULL;
}

PLATFORMS_MODULE_CLASS::PLATFORMS_MODULE_CLASS(
    PLATFORMS_MODULE p)
{
    // set parent
    parent = p;

    // set default name
    name = "noname";

    // initialize siblings and children to NULL
    next = NULL;
    prev = NULL;
    children = NULL;

    // add self to parent's child list
    if (parent != NULL)
    {
        parent->AddChild(this);
    }
}

PLATFORMS_MODULE_CLASS::PLATFORMS_MODULE_CLASS(
    PLATFORMS_MODULE p,
    string n)
{
    // set parent
    parent = p;

    // set name
    name = n;

    // initialize siblings and children to NULL
    next = NULL;
    prev = NULL;
    children = NULL;

    // add self to parent's child list
    if (parent != NULL)
    {
        parent->AddChild(this);
    }
}

// destructor: don't link this to explicit uninit
// chain. Destructors get chained automatically,
// and assuming discipline has been maintained in
// writing modules, the uninit tree should be a
// replica of the auto-destruction tree. Any node
// in the tree that needs to do something during
// destruction/uninit apart from the default
// chaining-to-children should make sure the
// node-specific code gets called on both paths.
PLATFORMS_MODULE_CLASS::~PLATFORMS_MODULE_CLASS()
{
}

// add child
void
PLATFORMS_MODULE_CLASS::AddChild(
    PLATFORMS_MODULE child)
{
    // sanity check
    assert(child->next == NULL && child->prev == NULL);

    //
    // add to list of children
    //

    // maintain doubly-linked circular list,
    // because Init() needs to call them in the
    // order they were constructed, while Uninit()
    // needs to call them in the reverse order.

    if (children != NULL)
    {
        PLATFORMS_MODULE first = children;
        PLATFORMS_MODULE last  = children->prev;

        last->next = child;
        child->prev = last;

        child->next = first;
        first->prev = child;
    }
    else
    {
        child->next = child;
        child->prev = child;

        children = child;
    }
}

// init
void
PLATFORMS_MODULE_CLASS::Init()
{
    // walk through list of children in FIFO order and init them
    if (children != NULL)
    {
        PLATFORMS_MODULE child = children;
        do
        {
            child->Init();
            child = child->next;
        }
        while (child != children);
    }
}

// init
void
PLATFORMS_MODULE_CLASS::Init(PLATFORMS_MODULE p)
{
    // walk through list of children in FIFO order and init them
    if (children != NULL)
    {
        PLATFORMS_MODULE child = children;
        do
        {
            child->Init();
            child = child->next;
        }
        while (child != children);
    }

    // set parent
    parent = p;

    // add self to parent's child list
    if (parent != NULL)
    {
        parent->AddChild(this);
    }
}

// uninit
void
PLATFORMS_MODULE_CLASS::Uninit()
{
    // walk through list of children in LIFO order and uninit them
    if (children != NULL)
    {
        PLATFORMS_MODULE child = children;
        do
        {
            child->Uninit();
            child = child->prev;
        }
        while (child != children);
    }
}

// callback-exit
void
PLATFORMS_MODULE_CLASS::CallbackExit(
    int exitcode)
{
    if (parent == NULL)
    {
        // chain-uninit, then exit
        Uninit();
        exit(exitcode);
    }
    else
    {
        // transfer to parent
        parent->CallbackExit(exitcode);
    }
}
