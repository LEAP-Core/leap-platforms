#ifndef __PLATFORMS_MODULE_H__
#define __PLATFORMS_MODULE_H__

#include <string>

using namespace std;

// =========== Platforms hardware/software module =========
typedef class PLATFORMS_MODULE_CLASS* PLATFORMS_MODULE;
class PLATFORMS_MODULE_CLASS
{
    protected:
        PLATFORMS_MODULE parent;   // parent module
        PLATFORMS_MODULE next;     // next sibling child module
        PLATFORMS_MODULE prev;     // prev sibling child module
        PLATFORMS_MODULE children; // list of children
        string       name;     // descriptive name

    public:
        // constructor - destructor
        PLATFORMS_MODULE_CLASS();
        PLATFORMS_MODULE_CLASS(PLATFORMS_MODULE);
        PLATFORMS_MODULE_CLASS(PLATFORMS_MODULE, string);
        ~PLATFORMS_MODULE_CLASS();

        // common methods
        void AddChild(PLATFORMS_MODULE);

        // common virtual methods
        virtual void Init();
        virtual void Init(PLATFORMS_MODULE parent);
        virtual void Uninit();
        virtual void CallbackExit(int);
};

#endif
