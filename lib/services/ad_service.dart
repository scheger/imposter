import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // Google Test-Rewarded-ID (Android)
  final String _testRewardedAdUnitIdAndroid = 'ca-app-pub-3940256099942544/5224354917';

  // Google Test-Rewarded-ID (iOS)
  final String _testRewardedAdUnitIdIos = 'ca-app-pub-3940256099942544/1712485313';


  AdService() {
    MobileAds.instance.initialize();
  }

  Future<void> loadRewardAd({
    required VoidCallback onLoaded,
    required VoidCallback onFailed,
  }) async {
    if (_isLoading) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: kDebugMode
      ? (defaultTargetPlatform == TargetPlatform.android
          ? _testRewardedAdUnitIdAndroid
          : _testRewardedAdUnitIdIos)
      : 'ca-app-pub-3940256099942544/5224354917', // deine echte Ad-ID !!!!!!!!!!!!!!!!!!!!!!!!!!!!
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _isLoading = false;
          _rewardedAd = ad;
          onLoaded();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          debugPrint('⚠️ RewardAd konnte nicht geladen werden: $error');
          onFailed();
        },
      ),
    );
  }

  Future<void> showRewardAd({
    required VoidCallback onUserEarnedReward,
    required VoidCallback onAdClosed,
  }) async {
    if (_rewardedAd == null) {
      debugPrint('⚠️ Keine RewardAd geladen');
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        debugPrint('⚠️ Ad konnte nicht gezeigt werden: $error');
        onAdClosed();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      onUserEarnedReward();
    });
  }
}
