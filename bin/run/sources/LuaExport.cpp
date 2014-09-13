#include "cocos2d.h"
#include "C2DXShareSDK/C2DXShareSDK.h"
#include "LuaExport.h"

using namespace std;
using namespace cocos2d;
using namespace cn::sharesdk;

void shareResultHandler(C2DXResponseState state, C2DXPlatType platType, CCDictionary *shareInfo, CCDictionary *error)
{
	switch (state) {
	case C2DXResponseStateSuccess:
		CCLog("����ɹ�");
		break;
	case C2DXResponseStateFail:
		CCLog("����ʧ��");
		break;
	default:
		break;
	}
}

void LuaExport::showShareMenu(const char *content, const char* image, const char* title, const char* des, const char* url)
{
	CCDictionary *dic = CCDictionary::create();
	dic->setObject(CCString::create(content), "content");
	dic->setObject(CCString::create(image), "image");
	dic->setObject(CCString::create(title), "title");
	dic->setObject(CCString::create(des), "description");
	dic->setObject(CCString::create(url), "url");
	dic->setObject(CCString::createWithFormat("%d", C2DXContentTypeNews), "type");

	C2DXShareSDK::showShareMenu(NULL, dic, CCPointMake(100, 100), C2DXMenuArrowDirectionUp, shareResultHandler);
}
