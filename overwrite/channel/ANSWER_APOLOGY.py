import re

def contains_apology(text):
    apology_phrases = [
        "很抱歉", "对不起", "抱歉", "无法提供", "不能提供", "不能浏览", "无法实时",
        "不能查询", "无法查询", "作为AI", "作为人工智能", "作为一个基于", "历史数据训练",
        "作为一个AI", "作为一个文本交互的AI", "无法直接回答"
    ]
    matched_phrases = []
    for phrase in apology_phrases:
        if phrase in text:
            position = text.index(phrase)
            # 如果文字不足100字，则按100字计算，目的是增加不足100字的文字的各项评分值
            score = 1 - (position / max(100, len(text)))
            score = round(score, 2)  # 将 score 四舍五入保留2位小数
            matched_phrases.append((phrase, score))
    return matched_phrases

def contains_alternative_suggestion(text):
    suggestion_phrases = [
        "建议您", "查询", "查阅", "查看", "访问", "使用", "通过", "联系", "获取", "查找"
    ]
    matched_phrases = []
    for phrase in suggestion_phrases:
        if phrase in text:
            position = text.index(phrase)
            # 如果文字不足100字，则按100字计算，目的是增加不足100字的文字的各项评分值
            score = 1 - (position / max(100, len(text)))
            score = round(score, 2)  # 将 score 四舍五入保留2位小数
            matched_phrases.append((phrase, score))
    return matched_phrases

def contains_information_terms(text):
    information_terms = [
        "信息", "数据", "消息", "动态", "最新预报", "天气", "气象", "最新的", "新闻"
    ]
    matched_terms = []
    for term in information_terms:
        if term in text:
            position = text.index(term)
            # 如果文字不足100字，则按100字计算，目的是增加不足100字的文字的各项评分值
            score = 1 - (position / max(100, len(text)))
            score = round(score, 2)  # 将 score 四舍五入保留2位小数
            matched_terms.append((term, score))
    return matched_terms

#判断 AI回复的文本 决定要不要实时搜索
def analyze_text_features__need_search(text):
    matched_apologies = contains_apology(text)
    matched_suggestions = contains_alternative_suggestion(text)
    matched_info_terms = contains_information_terms(text)
    
    matched_count = (len(matched_apologies) > 0) + (len(matched_suggestions) > 0) + (len(matched_info_terms) > 0)
    matched_features = {
        "抱歉类": matched_apologies,
        "建议类": matched_suggestions,
        "信息类": matched_info_terms
    }
    
    # 计算每一类的总评分值，并保留2位小数
    apologies_score_sum = round(sum(score for _, score in matched_apologies), 2)
    suggestions_score_sum = round(sum(score for _, score in matched_suggestions), 2)
    info_terms_score_sum = round(sum(score for _, score in matched_info_terms), 2)

    # 计算每一类的平均评分值，并保留2位小数
    apologies_avg_score = round(apologies_score_sum / max(1, len(matched_apologies)), 2)
    suggestions_avg_score = round(suggestions_score_sum / max(1, len(matched_suggestions)), 2)
    info_terms_avg_score = round(info_terms_score_sum / max(1, len(matched_info_terms)), 2)

    # 返回每一类的总评分值以及总的评分值
    sum_of_scores = apologies_score_sum + suggestions_score_sum + info_terms_score_sum
    sum_of_scores = round(sum_of_scores, 2)  # 将 score 四舍五入保留2位小数
    
    
    #增加计算 “修正后总分” 功能：目的是考虑 3 类词语的先后次序关系，作为判断依据之一
    #
    #如果 抱歉类平均分 > 建议类平均分 
    #则 修正后总分= 总分:{sum_of_scores} + 0.3
    #否则 修正后总分= 总分:{sum_of_scores} - 0.3
    #
    #如果 抱歉类平均分 > 信息类平均分 
    #则 修正后总分= 修正后总分 + 0.3
    #否则 修正后总分= 修正后总分 - 0.3
    # 
    adjusted_score = sum_of_scores
    if apologies_avg_score > suggestions_avg_score:
        adjusted_score += 0.3
    else:
        adjusted_score -= 0.3
    #
    if apologies_avg_score > info_terms_avg_score:
        adjusted_score += 0.3
    else:
        adjusted_score -= 0.3
    #
    adjusted_score = round(adjusted_score, 2)

    #把分析结果用美观的格式组成字符串，方便调用者直接显示查看结果
    analyze_result_string = (
        text[:60] + "\n" +
        f"词语:{word_count} 总分:{sum_of_scores} 明细:{features}\n" +
        f"三小类合计分: 抱歉类 {score_summaries['抱歉类总分']}, 建议类 {score_summaries['建议类总分']}, 信息类 {score_summaries['信息类总分']}\n" +
        f"三小类平均分: 抱歉类 {score_summaries['抱歉类平均分']}, 建议类 {score_summaries['建议类平均分']}, 信息类 {score_summaries['信息类平均分']}\n" +
        f"修正后总分:{adjusted_score}\n" +
        "--------------"
    )    

    return analyze_result_string, matched_count, matched_features, sum_of_scores, adjusted_score, {
        "抱歉类总分": apologies_score_sum,
        "建议类总分": suggestions_score_sum,
        "信息类总分": info_terms_score_sum,
        "抱歉类平均分": apologies_avg_score,
        "建议类平均分": suggestions_avg_score,
        "信息类平均分": info_terms_avg_score        
    }



