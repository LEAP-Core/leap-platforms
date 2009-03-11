#include <cstdlib>
#include <assert.h>

#include "platforms-module.h"

using namespace std;

// constructors
PLATFORMS_MODULE_CLASS::PLATFORMS_MODULE_CLASS()
{
    parent   = NULL;
    next     = NULL;
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
    assert(child->next == NULL);

    // add to list of children
    child->next = children;
    children = child;
}

// uninit
void
PLATFORMS_MODULE_CLASS::Uninit()
{
    // walk through list of children and uninit them
    PLATFORMS_MODULE child = children;
    while (child != NULL)
    {
        child->Uninit();
        child = child->next;
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
