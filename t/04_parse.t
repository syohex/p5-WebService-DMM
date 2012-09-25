use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw/mock_guard/;

use WebService::DMM;

subtest 'actual parse response', => sub {
    my $guard = mock_guard('Furl::Response', +{
        content => sub {
            local $/;
            <DATA>;
        },
        is_success => sub { 1 },
    },
    'Furl', +{
        get => sub { 'Furl::Response' },
    });

    my $dmm = WebService::DMM->new(
        affiliate_id => 'test-999',
        api_id       => 'test_api_id',
    );

    my @items = $dmm->search(
        site    => 'DMM.co.jp',
        service => 'digital',
        keyword => 'test_key',
    );

    is((scalar @items), 1, "return items");

    my $item = shift @items;
    isa_ok($item, "WebService::DMM::Item");

    is $item->content_id, 111, 'content id';
    is $item->product_id, 112, 'product id';
    is $item->title, 'test_title', 'title';
    is $item->url, 'http://example.com/', 'URL';
    is $item->affiliate_url, 'http://example.com/test-999', 'affiliate url';
    is $item->image('list'), 'http://pics.dmm.co.jp/testpt.jpg', 'image(list)';
    is $item->image('small'), 'http://pics.dmm.co.jp/testps.jpg', 'image(small)';
    is $item->image('large'), 'http://pics.dmm.co.jp/testpl.jpg', 'image(large)';
    is_deeply $item->sample_images, [
        'http://pics.dmm.co.jp/sample1.jpg',
        'http://pics.dmm.co.jp/sample2.jpg',
    ], 'sample image urls';
    is $item->price, '500-', 'from price';
    is $item->list_price, '1000', 'list price';
    is $item->date, '2012-02-07 10:00:43', 'date';
    is_deeply $item->keywords, ['key1', 'key2'], 'keywords';
    is $item->series, 'test_series', 'series';
    is $item->maker, 'test_maker', 'maker';
    is_deeply $item->actresses, ['test_actress1', 'test_actress2'], 'actresses';
    is_deeply $item->directors, ['test_director'], 'director';
    is $item->label, 'test_label', 'label';
};

done_testing;

__DATA__
<?xml version="1.0" encoding="euc-jp"?>
<responce>
  <request>
    <parameters>
      <parameter name="api_id" value="test_api_id" />
      <parameter name="affiliate_id" value="test-999" />
      <parameter name="operation" value="ItemList" />
      <parameter name="version" value="1.00" />
      <parameter name="timestamp" value="2012-01-13 14:08:16" />
      <parameter name="site" value="DMM.co.jp" />
      <parameter name="service" value="digital" />
      <parameter name="keyword" value="test_key" />
    </parameters>
  </request>
  <result>
    <result_count>20</result_count>
    <total_count>3880</total_count>
    <first_position>1</first_position>
    <items>
      <item>
        <service_name>test</service_name>
        <floor_name>video</floor_name>
        <category_name>video</category_name>
        <content_id>111</content_id>
        <product_id>112</product_id>
        <title>test_title</title>
        <URL>http://example.com/</URL>
        <affiliateURL>http://example.com/test-999</affiliateURL>
        <imageURL>
          <list>http://pics.dmm.co.jp/testpt.jpg</list>
          <small>http://pics.dmm.co.jp/testps.jpg</small>
          <large>http://pics.dmm.co.jp/testpl.jpg</large>
        </imageURL>
        <sampleImageURL>
          <sample_s>
            <image>http://pics.dmm.co.jp/sample1.jpg</image>
            <image>http://pics.dmm.co.jp/sample2.jpg</image>
          </sample_s>
        </sampleImageURL>
        <prices>
          <price>500-</price>
          <list_price>1000</list_price>
        </prices>
        <date>2012-02-07 10:00:43</date>
        <iteminfo>
          <keyword>
            <name>key1</name>
            <id>1</id>
          </keyword>
          <keyword>
            <name>key2</name>
            <id>2</id>
          </keyword>
          <series>
            <name>test_series</name>
            <id>3</id>
          </series>
          <maker>
            <name>test_maker</name>
            <id>4</id>
          </maker>
          <actress>
            <name>test_actress1</name>
            <id>10</id>
          </actress>
          <actress>
            <name>test actress1</name>
            <id>10_ruby</id>
          </actress>
          <actress>
            <name>av</name>
            <id>10_classify</id>
          </actress>
          <actress>
            <name>test_actress2</name>
            <id>20</id>
          </actress>
          <actress>
            <name>test actress2</name>
            <id>20_ruby</id>
          </actress>
          <actress>
            <name>av</name>
            <id>20_classify</id>
          </actress>
          <director>
            <name>test_director</name>
            <id>30</id>
          </director>
          <director>
            <name>test director</name>
            <id>30_ruby</id>
          </director>
          <label>
            <name>test_label</name>
            <id>40</id>
          </label>
        </iteminfo>
      </item>
    </items>
  </result>
</responce>
